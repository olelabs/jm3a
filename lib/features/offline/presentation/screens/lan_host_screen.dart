import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jma3a/features/offline/services/lan_service.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/app_logger.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../games/engine/base_game_engine.dart';
import '../../data/offline_game_provider.dart';
import '../../domain/offline_session.dart';
import 'offline_play_screen.dart';

// ── Host screen ───────────────────────────────────────────────────────────────

class LanHostScreen extends StatefulWidget {
  const LanHostScreen({
    super.key,
    required this.hostName,
    required this.config,
    required this.gameType,
    required this.pack,
  });

  final String hostName;
  final GameConfig config;
  final GameType gameType;
  final OfflinePack pack;

  @override
  State<LanHostScreen> createState() => _LanHostScreenState();
}

class _LanHostScreenState extends State<LanHostScreen> {
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted) _startHosting();
    });
  }

  Future<void> _startHosting() async {
    final provider = context.read<OfflineGameProvider>();
    await provider.startLanHost(
      gameType: widget.gameType,
      config: widget.config,
      playerNames: [widget.hostName],
      packId: widget.pack.id,
      packName: widget.pack.name,
      hostName: widget.hostName,
    );
  }

  Future<void> _launch() async {
    final provider = context.read<OfflineGameProvider>();
    setState(() => _isStarting = true);

    // Broadcast start to all clients, then navigate
    await provider.startLanGame();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: const OfflinePlayScreen(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(title: const Text('LAN Room')),
      body: Consumer<OfflineGameProvider>(
        builder: (ctx, game, _) {
          if (game.loadState == OfflineLoadState.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('❌', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      game.error ?? 'Failed to start',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Go back'),
                    ),
                  ],
                ),
              ),
            );
          }

          final session = game.session;
          final sessionPlayers = session?.players ?? [];
          final joinedPlayers = sessionPlayers.skip(1).toList();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room info banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.navyBlue, AppColors.navyBlueLight],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Text('📡', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Room is broadcasting',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${widget.hostName}\'s Room',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${widget.gameType.displayName} • ${widget.pack.name}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 24),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.infoBlue.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.infoBlue.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.infoBlue,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Other players: open Jma3a → Play → LAN → Join Room',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.infoBlue.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 60.ms).fadeIn(),

                const SizedBox(height: 20),

                // Players
                Row(
                  children: [
                    Text(
                      'Players — ${sessionPlayers.length}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    // Only show spinner while initially loading, not in lobby
                    if (game.loadState == OfflineLoadState.loading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Host chip
                _PlayerChip(name: widget.hostName, isHost: true),

                // Connected peers
                ...joinedPlayers.asMap().entries.map(
                  (e) => _PlayerChip(
                    name: e.value.name,
                    isHost: false,
                    isConnected: true,
                  ).animate(delay: (e.key * 40).ms).fadeIn(),
                ),

                const Spacer(),

                JButton(
                  label: joinedPlayers.isEmpty
                      ? 'Start Solo'
                      : 'Start Game (\${sessionPlayers.length})',
                  onPressed:
                      (game.loadState == OfflineLoadState.ready ||
                          game.loadState == OfflineLoadState.lobby)
                      ? _launch
                      : null,
                  isLoading: _isStarting,
                  icon: Icons.play_arrow_rounded,
                ).animate(delay: 100.ms).fadeIn(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    required this.name,
    required this.isHost,
    this.isConnected = true,
  });
  final String name;
  final bool isHost;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: JCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isConnected
                    ? AppColors.successGreen
                    : AppColors.warningAmber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              name,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (isHost)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.ownerBadge.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'HOST',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ownerBadge,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Join screen ───────────────────────────────────────────────────────────────

class LanJoinScreen extends StatefulWidget {
  const LanJoinScreen({super.key});

  @override
  State<LanJoinScreen> createState() => _LanJoinScreenState();
}

class _LanJoinScreenState extends State<LanJoinScreen> {
  final _nameCtrl = TextEditingController();
  final _lan = LanService.instance;
  LanRoomDescriptor? _selectedRoom;
  List<LanRoomDescriptor> _rooms = [];
  bool _isConnecting = false;
  StreamSubscription<LanRoomDescriptor>? _roomSub;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted)
        setState(() {
          _rooms = _rooms.where((r) => !r.isStale).toList();
        });
    });
  }

  Future<void> _startDiscovery() async {
    _roomSub?.cancel();
    try {
      await _lan.startDiscovery();
      _roomSub = _lan.roomStream.listen((room) {
        if (!mounted) return;
        setState(() {
          _rooms = [
            ..._rooms.where((r) => r.sessionId != room.sessionId && !r.isStale),
            room,
          ];
        });
      });
    } catch (e) {
      AppLogger.warning('LanJoin: discovery failed: $e');
    }
  }

  /// Restart discovery after a failed join attempt
  Future<void> _restartDiscovery() async {
    setState(() {
      _isConnecting = false;
      _selectedRoom = null;
    });
    await _startDiscovery();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roomSub?.cancel();
    _refreshTimer?.cancel();
    // Stop UDP discovery to free the port, but keep TCP connection alive
    _lan.stopDiscovery();
    super.dispose();
  }

  Future<void> _join() async {
    if (_selectedRoom == null || _nameCtrl.text.trim().isEmpty) return;
    setState(() => _isConnecting = true);

    final provider = context.read<OfflineGameProvider>();
    final playerId = DateTime.now().millisecondsSinceEpoch.toString();
    final ok = await provider.connectToRoom(
      room: _selectedRoom!,
      playerId: playerId,
      playerName: _nameCtrl.text.trim(),
    );

    if (!mounted) return;

    if (!ok) {
      setState(() => _isConnecting = false);
      context.showErrorSnackBar(provider.lanError ?? 'Connection failed');
      return;
    }

    // Wait for provider to reach lobby or ready state.
    // Use a Completer + listener so we react the instant state changes,
    // rather than polling every 150ms and potentially missing a fast response.
    final completer = Completer<void>();
    void listener() {
      if (provider.isLobby || provider.isReady) {
        if (!completer.isCompleted) completer.complete();
      }
      if (provider.loadState == OfflineLoadState.error) {
        if (!completer.isCompleted)
          completer.completeError(provider.error ?? 'error');
      }
    }

    provider.addListener(listener);

    try {
      // Also check immediately in case we already transitioned
      if (provider.isLobby || provider.isReady) {
        completer.complete();
      }
      await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('No response from host'),
      );
    } on TimeoutException {
      if (mounted) {
        setState(() => _isConnecting = false);
        context.showErrorSnackBar('Host did not respond. Try again.');
      }
      provider.removeListener(listener);
      return;
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        context.showErrorSnackBar('Connection error: $e');
      }
      provider.removeListener(listener);
      return;
    }
    provider.removeListener(listener);

    if (!mounted) return;
    setState(() => _isConnecting = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const OfflinePlayScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final rooms = _rooms.where((r) => !r.isStale && !r.isFull).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Join LAN Room')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Your name',
                prefixIcon: Icon(Icons.person_outline_rounded),
                hintText: 'Enter your name to join',
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}), // re-evaluate button state
            ).animate().fadeIn(),

            const SizedBox(height: 24),

            Row(
              children: [
                Text(
                  'Nearby rooms',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Expanded(
              child: rooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📡', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            'Scanning for rooms…',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Make sure host device is on the same WiFi.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      children: rooms.asMap().entries.map((e) {
                        final room = e.value;
                        final isSelected =
                            _selectedRoom?.sessionId == room.sessionId;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedRoom = room),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.tealGreen.withOpacity(0.08)
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.tealGreen
                                    : theme.colorScheme.outlineVariant,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '📡',
                                  style: TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        room.hostName,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      Text(
                                        '${room.gameType.displayName} • '
                                        '${room.packName} • '
                                        '${room.playerCount}/${room.maxPlayers} players',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.tealGreen,
                                  ),
                              ],
                            ),
                          ).animate(delay: (e.key * 40).ms).fadeIn(),
                        );
                      }).toList(),
                    ),
            ),

            JButton(
              label: 'Join Room',
              onPressed:
                  _selectedRoom != null && _nameCtrl.text.trim().isNotEmpty
                  ? _join
                  : null,
              isLoading: _isConnecting,
              icon: Icons.wifi_tethering_rounded,
            ).animate(delay: 60.ms).fadeIn(),
            if (_selectedRoom != null && _nameCtrl.text.trim().isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Enter your name above to join',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
