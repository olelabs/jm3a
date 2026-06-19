import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jma3a/Sticker.dart';
import 'package:jma3a/core/router/app_router.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/never_have_i_ever/never_have_i_ever_engine.dart';
import 'package:jma3a/features/games/truth_or_dare/data/tod_repository.dart';
import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_logger.dart';
// import '../../../games/engine/base_game_engine.dart';
// import '../../../games/shared/stickers.dart';
// import '../../../games/truth_or_dare/data/tod_repository.dart';
// import '../never_have_i_ever_engine.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

enum NhieLoadState { idle, loading, ready, error, gameOver }

class NhieGameProvider extends ChangeNotifier {
  NhieGameProvider({
    required RealtimeService realtimeService,
    required String userId,
    required String displayName,
  }) : _realtime = realtimeService,
       _userId = userId,
       _displayName = displayName;

  final RealtimeService _realtime;
  final String _userId, _displayName;
  NeverHaveIEverEngine? _engine;
  NhieLoadState _loadState = NhieLoadState.idle;
  String? _roomId;
  bool _isOwner = false;
  String _error = '';

  NhieLoadState get loadState => _loadState;
  NhieState? get state => _engine?.currentState as NhieState?;
  String get userId => _userId;
  bool get isOwner => _isOwner;
  String get error => _error;

  Future<void> initAsOwner({
    required String roomId,
    required String packId,
    required List<String> playerIds,
    required Map<String, String> displayNames,
    required GameConfig config,
  }) async {
    _roomId = roomId;
    _isOwner = true;
    _loadState = NhieLoadState.loading;
    notifyListeners();
    try {
      var todCards = await TodRepository.instance.loadCardsFromCache(
        packId: packId,
        language: config.language,
      );
      if (todCards.isEmpty) {
        final rows = await Supabase.instance.client
            .from('pack_cards')
            .select('id, content, card_type, difficulty, sort_order')
            .eq('pack_id', packId)
            .order('sort_order');
        todCards = (rows as List).map((r) {
          String text = '';
          final raw = r['content'];
          if (raw is Map) {
            final m = Map<String, dynamic>.from(raw as Map);
            text =
                (m[config.language] ??
                        m['en'] ??
                        m.values.whereType<String>().firstOrNull ??
                        '')
                    as String;
          } else if (raw is String) {
            try {
              final d = jsonDecode(raw);
              if (d is Map)
                text = (d[config.language] ?? d['en'] ?? '') as String;
              else
                text = raw;
            } catch (_) {
              text = raw;
            }
          }
          return TodCard(
            id: r['id'] as String,
            content: text,
            type: TodCardType.truth,
            difficulty: TodDifficulty.mild,
          );
        }).toList();
      }
      final cards = todCards.map((c) {
        var t = c.content;
        for (final p in ['Never have I ever ', 'never have I ever ']) {
          if (t.startsWith(p)) {
            t = t.substring(p.length);
            break;
          }
        }
        if (t.isNotEmpty) t = t[0].toUpperCase() + t.substring(1);
        return NhieCard(id: c.id, content: t, difficulty: c.difficulty.name);
      }).toList();
      _engine = NeverHaveIEverEngine(config, cards: cards);
      _engine!.init(playerIds);
      _loadState = NhieLoadState.ready;
      notifyListeners();
      _broadcastState();
    } catch (e) {
      _error = e.toString();
      _loadState = NhieLoadState.error;
      AppLogger.error('NhieProvider: init failed', error: e);
      notifyListeners();
    }
  }

  void initAsFollower(String roomId) {
    _roomId = roomId;
    _isOwner = false;
    _loadState = NhieLoadState.loading;
    notifyListeners();
  }

  Future<void> vote(bool haveI, {String message = ''}) => _handleAction({
    'action': 'nhie_vote',
    'have_i': haveI,
    'message': message,
  });
  Future<void> sendReaction(String emoji) =>
      _handleAction({'action': 'nhie_reaction', 'sticker': emoji});
  Future<void> ownerAdvanceTurn() async {
    if (!_isOwner || _engine == null) return;
    _engine!.advanceTurn();
    if (_engine!.isGameOver) _loadState = NhieLoadState.gameOver;
    notifyListeners();
    _broadcastState();
  }

  void onStateBroadcast(Map<String, dynamic> payload) {
    if (_isOwner) return;
    try {
      final snap =
          (payload['snapshot'] as Map<String, dynamic>?)?['state']
              as Map<String, dynamic>? ??
          payload['state'] as Map<String, dynamic>?;
      if (snap == null) return;
      _engine ??= NeverHaveIEverEngine(
        const GameConfig(
          maxRounds: 10,
          turnTimerSeconds: 60,
          allowSkip: false,
          allowSpicy: false,
        ),
        cards: [],
      );
      _engine!.restoreFromSnapshot(snap);
      _loadState = _engine!.isGameOver
          ? NhieLoadState.gameOver
          : NhieLoadState.ready;
      notifyListeners();
    } catch (e) {
      AppLogger.warning('NhieProvider: restore failed: $e');
    }
  }

  void onPlayerAction(Map<String, dynamic> payload) {
    if (!_isOwner || _engine == null) return;
    final action = payload['action'] as String?;
    final uid = payload['user_id'] as String?;
    final ts = payload['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    if (uid == null) return;
    if (action == 'nhie_vote') {
      _engine!.handleEvent(
        NhieVoteEvent(
          userId: uid,
          ts: ts,
          haveI: payload['have_i'] as bool? ?? false,
          message: payload['message'] as String? ?? '',
        ),
      );
    } else if (action == 'nhie_reaction') {
      _engine!.handleEvent(
        NhieReactionEvent(
          userId: uid,
          ts: ts,
          sticker: payload['sticker'] as String? ?? '😂',
        ),
      );
    }
    if (_engine!.isGameOver) _loadState = NhieLoadState.gameOver;
    notifyListeners();
    _broadcastState();
  }

  void onSyncRequest(Map<String, dynamic> _) {
    if (_isOwner) _broadcastState();
  }

  Future<void> _handleAction(Map<String, dynamic> action) async {
    final full = {
      ...action,
      'user_id': _userId,
      'display_name': _displayName,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    if (_isOwner && _engine != null)
      onPlayerAction(full);
    else if (_roomId != null)
      await _realtime.broadcastPlayerAction(_roomId!, full);
  }

  void _broadcastState() {
    if (_roomId == null || _engine == null) return;
    _realtime.broadcastGameState(_roomId!, {
      'state': _engine!.serializeState(),
    }, _userId).ignore();
  }
}

// ── Confirm leave dialog ──────────────────────────────────────────────────────

Future<void> nhieShowLeaveDialog(
  BuildContext ctx, {
  required String roomId,
  required bool isOwners,
}) async {
  if (!ctx.mounted) return;
  final isOwner = isOwners;
  if (isOwner) {
    final choice = await showDialog<String>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('Leave Game?'),
        content: const Text("Choose what happens while you're away."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, 'cancel'),
            child: const Text('Stay'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(d, 'pause'),
            child: const Text('Pause & Return Later'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(d, 'end'),
            child: const Text('End Game for Everyone'),
          ),
        ],
      ),
    );
    if (choice == null || choice == 'cancel' || !ctx.mounted) return;
    if (choice == 'pause') {
      try {
        await sl.roomRepository.updateStatus(roomId, RoomStatus.paused);
        await sl.realtimeService.broadcastRoomEvent(roomId, {
          'type': 'game_paused',
          'reason': 'host_away',
        });
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (_) {}
      if (ctx.mounted) AppRouter.router.go(RouteNames.home);
    } else {
      try {
        await sl.realtimeService.broadcastGameEnded(roomId, {
          'reason': 'host_ended',
        });
        await sl.realtimeService.broadcastRoomEvent(roomId, {
          'type': 'owner_left',
          'reason': 'host_ended',
        });
        await sl.roomRepository.updateStatus(roomId, RoomStatus.closed);
      } catch (_) {}
      if (ctx.mounted) AppRouter.router.go(RouteNames.home);
    }
  } else {
    final choice = await showDialog<String>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('Leave Game?'),
        content: const Text('Are you leaving for good or will you come back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, 'cancel'),
            child: const Text('Stay'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(d, 'return'),
            child: const Text("I'll Return"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(d, 'definitive'),
            child: const Text('Leave for Good'),
          ),
        ],
      ),
    );
    if (choice == null || choice == 'cancel' || !ctx.mounted) return;
    try {
      if (choice == 'return') {
        await sl.roomRepository.setMemberAway(
          roomId,
          ctx.read<AuthProvider>().currentUser!.id,
          away: true,
        );
      } else {
        await sl.roomRepository.setMemberDefinitiveLeave(
          roomId,
          ctx.read<AuthProvider>().currentUser!.id,
        );
      }
    } catch (_) {}
    if (ctx.mounted) AppRouter.router.go(RouteNames.home);
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class NhieGameScreen extends StatefulWidget {
  const NhieGameScreen({
    super.key,
    required this.roomId,
    required this.config,
    required this.playerIds,
    required this.playerDisplayNames,
    required this.packId,
    this.packCoverUrl,
    required this.isOwner,
    this.isModerator = false,
  });
  final String roomId;
  final GameConfig config;
  final List<String> playerIds;
  final Map<String, String> playerDisplayNames;
  final String packId;
  final bool isOwner;
  final bool isModerator;
  final String? packCoverUrl;
  @override
  State<NhieGameScreen> createState() => _NhieGameScreenState();
}

class _NhieGameScreenState extends State<NhieGameScreen> {
  late final NhieGameProvider _provider;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser!;
    _provider = NhieGameProvider(
      realtimeService: sl.realtimeService,
      userId: user.id,
      displayName: user.displayName ?? user.username ?? 'Player',
    );
    // Update callbacks on existing channel (no teardown needed)
    sl.realtimeService.subscribe(
      roomId: widget.roomId,
      onGameState: (p) => _provider.onStateBroadcast(p),
      onPlayerAction: (p) => _provider.onPlayerAction(p),
      onSyncRequest: (p) => _provider.onSyncRequest(p),
      onGameStarted: (_) {},
      onGameEnded: (p) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('The host ended the game')),
          );
          if (context.canPop())
            context.pop();
          else
            context.go(RouteNames.home);
        }
      },
      onRoomEvent: (p) {
        if ((p['type'] as String?) == 'game_paused' && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx2) => AlertDialog(
                title: const Text('⏸ Game Paused'),
                content: const Text(
                  'The host paused the game and will return shortly.',
                ),
                actions: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(ctx2).pop();
                      AppRouter.router.go(RouteNames.home);
                    },
                    child: const Text('Leave for Now'),
                  ),
                ],
              ),
            );
          });
        }
        if (((p['type'] as String?) == 'room_closed' ||
            (p['type'] as String?) == 'owner_left')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted)
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx2) => AlertDialog(
                  title: const Text('Room Closed'),
                  content: const Text('The host closed the room.'),
                  actions: [
                    FilledButton(
                      onPressed: () {
                        Navigator.of(ctx2).pop();
                        AppRouter.router.go(RouteNames.home);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            else
              AppRouter.router.go(RouteNames.home);
          });
        }
      },
      onChatMessage: (_) {},
      onModeration: (p) {
        final type = p['type'] as String?;
        final targetId = p['target_user_id'] as String?;
        final myId = context.read<AuthProvider>().currentUser?.id;
        if ((type == 'kick' || type == 'ban') && targetId == myId && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                type == 'kick'
                    ? 'You were removed from the room'
                    : 'You were banned from this room',
              ),
            ),
          );
          context.go(RouteNames.home);
        }
      },
      onSettingsChange: (_) {},
      onPresenceSync: (_) {},
      onPresenceJoin: (_) {},
      onPresenceLeave: (_) {},
      onStatusChange: (_) {},
    );
    // Send sync request after short delay so owner's response arrives on active channel
    if (!widget.isOwner) {
      Future.delayed(const Duration(milliseconds: 300), _requestSync);
    }
    if (widget.isOwner) {
      _provider.initAsOwner(
        roomId: widget.roomId,
        packId: widget.packId,
        playerIds: widget.playerIds,
        displayNames: widget.playerDisplayNames,
        config: widget.config,
      );
    } else {
      _provider.initAsFollower(widget.roomId);
    }
  }

  void _requestSync() {
    if (!mounted) return;
    // Send immediately, then retry after 1s and 3s in case owner missed it
    sl.realtimeService
        .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
        .ignore();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _provider.loadState == NhieLoadState.loading) {
        sl.realtimeService
            .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
            .ignore();
      }
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _provider.loadState == NhieLoadState.loading) {
        sl.realtimeService
            .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
            .ignore();
      }
    });
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<NhieGameProvider>(
        builder: (ctx, game, _) {
          if (game.loadState == NhieLoadState.loading)
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          if (game.loadState == NhieLoadState.error)
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error: ${game.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          if (game.loadState == NhieLoadState.gameOver)
            return _GameOverScreen(
              game: game,
              displayNames: widget.playerDisplayNames,
            );
          final state = game.state;
          if (state == null)
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          return _GameBody(
            game: game,
            state: state,
            displayNames: widget.playerDisplayNames,
            packCoverUrl: widget.packCoverUrl,
            roomId: widget.roomId,
            isOwner: widget.isOwner,
          );
        },
      ),
    );
  }
}

// ── Game body ─────────────────────────────────────────────────────────────────

class _GameBody extends StatefulWidget {
  const _GameBody({
    required this.game,
    required this.state,
    required this.displayNames,
    this.packCoverUrl,
    required this.roomId,
    required this.isOwner,
  });
  final NhieGameProvider game;
  final NhieState state;
  final Map<String, String> displayNames;
  final String? packCoverUrl;
  final String roomId;
  final bool isOwner;
  @override
  State<_GameBody> createState() => _GameBodyState();
}

class _GameBodyState extends State<_GameBody> {
  final _msgCtrl = TextEditingController();
  bool _showHistory = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  String _name(String id) =>
      widget.displayNames[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final state = widget.state;
    final game = widget.game;
    final hasVoted = state.voteEntries.containsKey(game.userId);
    final allVoted = state.playerOrder.every(
      (id) => state.voteEntries.containsKey(id),
    );
    final hasReacted = state.reactions.any((r) => r.userId == game.userId);
    final reactionTally = <String, int>{};
    for (final r in state.reactions) {
      reactionTally[r.sticker] = (reactionTally[r.sticker] ?? 0) + 1;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await nhieShowLeaveDialog(
          context,
          roomId: widget.roomId,
          isOwners: widget.isOwner,
        );
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => nhieShowLeaveDialog(
              context,
              roomId: widget.roomId,
              isOwners: widget.isOwner,
            ),
          ),
          title: Text('Round ${state.roundNumber} / ${state.maxRounds}'),
          actions: [
            if (state.history.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.history_rounded),
                onPressed: () => setState(() => _showHistory = !_showHistory),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '🍹 ${state.scores.values.fold(0, (a, b) => a + b)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _showHistory
            ? _HistoryPanel(
                history: state.history,
                displayNames: widget.displayNames,
                onClose: () => setState(() => _showHistory = false),
              )
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Current player ───────────────────────────────────
                      Text(
                        "${_name(state.currentPlayerId)}'s turn",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Card with background image ─────────────────────
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: SizedBox(
                                width: constraints.maxWidth,
                                height: constraints.maxHeight,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Background
                                    Positioned.fill(
                                      child:
                                          widget.packCoverUrl != null &&
                                              widget.packCoverUrl!.isNotEmpty
                                          ? Image.network(
                                              widget.packCoverUrl!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              errorBuilder: (_, __, ___) =>
                                                  Image.asset(
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
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                    color: AppColors.tealGreen,
                                                  ),
                                            ),
                                    ),
                                    // Tint overlay
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.tealGreen.withOpacity(
                                                0.45,
                                              ),
                                              const Color(
                                                0xFF0D1B2A,
                                              ).withOpacity(0.65),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Content
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 20,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            '🍹',
                                            style: TextStyle(fontSize: 56),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Never Have I Ever…',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black54,
                                                  blurRadius: 6,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            state.currentCard?.content ?? '…',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w600,
                                              height: 1.5,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black54,
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Vote / waiting / results ─────────────────────────
                      if (!hasVoted && state.isVotingOpen) ...[
                        TextField(
                          controller: _msgCtrl,
                          maxLength: 120,
                          maxLines: 1,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          decoration: const InputDecoration(
                            hintText: 'Add a comment (optional)…',
                            border: OutlineInputBorder(),
                            isDense: true,
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: FilledButton.icon(
                                  onPressed: () => game.vote(
                                    true,
                                    message: _msgCtrl.text.trim(),
                                  ),
                                  icon: const Text('✋'),
                                  label: const Text(
                                    'I HAVE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.errorRed,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: FilledButton.icon(
                                  onPressed: () => game.vote(
                                    false,
                                    message: _msgCtrl.text.trim(),
                                  ),
                                  icon: const Text('🙅'),
                                  label: const Text(
                                    'NEVER',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        theme.colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (!allVoted && hasVoted) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Waiting… ${state.voteEntries.length}/${state.playerOrder.length}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ] else if (allVoted) ...[
                        ...state.voteEntries.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _name(e.key),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: e.key == game.userId
                                        ? theme.colorScheme.primary
                                        : null,
                                  ),
                                ),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      e.value.haveI ? '✋ I have' : '🙅 Never',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: e.value.haveI
                                                ? AppColors.errorRed
                                                : AppColors.tealGreen,
                                          ),
                                    ),
                                    if (e.value.message.isNotEmpty)
                                      Text(
                                        '"${e.value.message}"',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontStyle: FontStyle.italic,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (game.isOwner)
                          SizedBox(
                            height: 46,
                            child: FilledButton(
                              onPressed: game.ownerAdvanceTurn,
                              child: const Text('Next Card →'),
                            ),
                          )
                        else
                          Text(
                            'Waiting for host…',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],

                      // ── Reactions — pinned to bottom ─────────────────────
                      const SizedBox(height: 8),
                      if (reactionTally.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: reactionTally.entries
                                .map(
                                  (e) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${e.key} ${e.value}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      EmojiReactionRow(
                        reactionsByEmoji: const {},
                        alreadyReacted: hasReacted,
                        onReact: game.sendReaction,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// ── History panel ─────────────────────────────────────────────────────────────

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.history,
    required this.displayNames,
    required this.onClose,
  });
  final List<NhieRoundRecord> history;
  final Map<String, String> displayNames;
  final VoidCallback onClose;

  String _name(String id) =>
      displayNames[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.history_rounded),
          title: Text(
            'History (${history.length} rounds)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
        ),
        const Divider(height: 0),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: history.length,
            itemBuilder: (_, i) {
              final round = history[history.length - 1 - i];
              final haves = round.votes.values.where((v) => v.haveI).length;
              final nevers = round.votes.values.where((v) => !v.haveI).length;
              // Reaction tally
              final rt = <String, int>{};
              for (final r in round.reactions)
                rt[r.sticker] = (rt[r.sticker] ?? 0) + 1;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      '${round.roundNumber}',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  title: Text(
                    round.card.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '✋ $haves  •  🙅 $nevers  ${rt.isNotEmpty ? '• ' + rt.entries.map((e) => '${e.key}${e.value}').join(' ') : ''}',
                    style: theme.textTheme.bodySmall,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: round.votes.entries
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _name(e.key),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(e.value.haveI ? '✋' : '🙅'),
                                    if (e.value.message.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '"${e.value.message}"',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontStyle: FontStyle.italic,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Game over ─────────────────────────────────────────────────────────────────

class _GameOverScreen extends StatefulWidget {
  const _GameOverScreen({required this.game, required this.displayNames});
  final NhieGameProvider game;
  final Map<String, String> displayNames;
  @override
  State<_GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<_GameOverScreen> {
  bool _showHistory = false;
  String _name(String id) =>
      widget.displayNames[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

  @override
  Widget build(BuildContext context) {
    final scores = widget.game.state?.scores ?? {};
    final history = widget.game.state?.history ?? [];
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    const medals = ['🥇', '🥈', '🥉'];

    if (_showHistory)
      return Scaffold(
        appBar: AppBar(
          title: const Text('Game History'),
          leading: BackButton(
            onPressed: () => setState(() => _showHistory = false),
          ),
        ),
        body: _HistoryPanel(
          history: history,
          displayNames: widget.displayNames,
          onClose: () => setState(() => _showHistory = false),
        ),
      );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '🏆',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 72),
              ),
              Text(
                'Game Over!',
                textAlign: TextAlign.center,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Most 🍹 drinks wins!',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (_, i) {
                    final e = sorted[i];
                    return ListTile(
                      leading: Text(
                        i < medals.length ? medals[i] : '${i + 1}.',
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        _name(e.key),
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: Text(
                        '${e.value} 🍹',
                        style: context.textTheme.titleMedium?.copyWith(
                          color: AppColors.errorRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (history.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () => setState(() => _showHistory = true),
                  icon: const Icon(Icons.history_rounded),
                  label: Text('View History (${history.length} rounds)'),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => context.go(RouteNames.home),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
