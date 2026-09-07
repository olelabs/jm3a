import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/platform_config_provider.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/app_tutorial_service.dart';
import '../../../../shared/widgets/tutorial/screen_tutorial.dart';
import '../../../notifications/presentation/notification_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../../../packs/presentation/pack_provider.dart';
import '../../../packs/presentation/widgets/promoted_packs_carousel.dart';
import '../../data/room_cache_service.dart';
import '../../domain/room_entity.dart';
import '../widgets/active_room_conflict_dialog.dart';
import '../widgets/create_room_sheet.dart';
import '../widgets/join_code_dialog.dart';
import '../widgets/room_card.dart';
import 'closed_rooms_screen.dart';

class RoomBrowserScreen extends StatefulWidget {
  const RoomBrowserScreen({super.key});
  @override
  State<RoomBrowserScreen> createState() => _RoomBrowserScreenState();
}

class _RoomBrowserScreenState extends State<RoomBrowserScreen>
    with WidgetsBindingObserver {
  static const _pageSize = 20;

  List<RoomEntity> _rooms = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isCreating = false;
  String? _gameTypeFilter;
  Timer? _autoRefreshTimer;
  RealtimeChannel? _roomsCdcChannel;

  // ── Pagination ─────────────────────────────────────────────────────────────
  // Same page/hasMore/isLoadingMore idiom as NotificationProvider and
  // PackProvider's browse lists — see notification_provider.dart's
  // _loadNotifications / pack_provider.dart's loadBrowsePacks.
  int _page = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final _scrollCtrl = ScrollController();

  // First-time Room Browser tutorial targets.
  final GlobalKey _createFabKey = GlobalKey();
  final GlobalKey _joinCodeKey = GlobalKey();
  final GlobalKey _filterKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      sl.realtimeService.unsubscribeAll();
    } catch (_) {}
    _scrollCtrl.addListener(_onScroll);
    _loadRooms(fromCache: true);
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadRooms(),
    );
    // A closed room previously lingered in this list for up to 30s (the
    // poll interval above) — RLS already scopes visible rows to public/
    // member rooms, so no extra filter is needed here, just an instant
    // removal the moment a currently-displayed room's status flips.
    _roomsCdcChannel = Supabase.instance.client
        .channel('room_browser_rooms_cdc')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'rooms',
          callback: (payload) {
            final row = payload.newRecord;
            // Batch D: a keep-game close (closed_at set) also removes the room
            // from Browse instantly, without waiting for the periodic refresh.
            final terminallyGone =
                row['status'] == 'closed' || row['deleted_at'] != null;
            final keepGameClosed = row['closed_at'] != null;
            if (!terminallyGone && !keepGameClosed) return;
            if (!mounted) return;
            // OWNER EXCEPTION (Batch D): a keep-game-closed room stays
            // discoverable to its OWNER (getPublicRooms adds it back for them)
            // so they can always re-enter/reopen it. Do NOT instantly remove
            // the owner's own keep-game-closed room here — only a terminal
            // teardown (status=closed / deleted_at) removes it for the owner
            // too. Everyone else still has it removed the moment it closes.
            final myId = Supabase.instance.client.auth.currentUser?.id;
            final isMine = myId != null && row['owner_id'] == myId;
            if (keepGameClosed && !terminallyGone && isMine) return;
            final id = row['id'] as String?;
            if (id == null) return;
            setState(() => _rooms.removeWhere((r) => r.id == id));
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    _roomsCdcChannel?.unsubscribe();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadRooms();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMoreRooms();
    }
  }

  Future<void> _loadRooms({bool fromCache = false}) async {
    if (fromCache) {
      final cached = await RoomCacheService.instance.getCachedRooms();
      if (cached.isNotEmpty && mounted) {
        setState(() {
          _rooms = cached;
          _isLoading = false;
        });
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoading = _rooms.isEmpty;
      _hasError = false;
    });

    try {
      final userId = context.read<AuthProvider>().currentUser?.id;
      final rooms = await sl.roomRepository.getPublicRooms(
        limit: _pageSize,
        gameTypeFilter: _gameTypeFilter,
        userId: userId,
      );
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _isLoading = false;
        _page = 1;
        _hasMore = rooms.length == _pageSize;
      });
      await RoomCacheService.instance.cacheRooms(rooms);
    } catch (e, st) {
      debugPrint('RoomBrowser error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _hasError = _rooms.isEmpty;
        _isLoading = false;
      });
      if (_rooms.isEmpty) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _loadRooms();
      }
    }
  }

  /// Appends the next page of PUBLIC rooms only — the owned/member/paused
  /// merge in getPublicRooms is bounded by the user's own memberships and
  /// was already fully included on page 0 (includeUserRooms: false here
  /// avoids re-fetching and re-appending those same rows on every page).
  /// Existing ids are skipped so a room whose last_active_at shifted
  /// between page loads can't be appended twice.
  Future<void> _loadMoreRooms() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final userId = context.read<AuthProvider>().currentUser?.id;
      final nextPage = await sl.roomRepository.getPublicRooms(
        limit: _pageSize,
        offset: _page * _pageSize,
        gameTypeFilter: _gameTypeFilter,
        userId: userId,
        includeUserRooms: false,
      );
      if (!mounted) return;
      final existingIds = _rooms.map((r) => r.id).toSet();
      final newRooms = nextPage.where((r) => !existingIds.contains(r.id));
      setState(() {
        _rooms = [..._rooms, ...newRooms];
        _page++;
        _hasMore = nextPage.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('RoomBrowser loadMore error: $e');
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _createRoom() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);
    try {
      await _doCreateRoom();
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _doCreateRoom() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final active = await sl.roomRepository.getActiveMembership(user.id);
    if (active != null) {
      if (!mounted) return;
      final result = await resolveActiveRoomConflict(context, active);
      if (result == ActiveRoomConflictResult.closedAndProceed && mounted) {
        _doCreateRoom();
      }
      return;
    }

    final myPacks = await sl.packRepository.getMyPurchasedPacks(user.id);
    if (myPacks.isEmpty) {
      final freeAvailable = await sl.packRepository.hasFreePacksAvailable();
      if (!freeAvailable) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.l10n.roomsNoPacksTitle),
            content: Text(context.l10n.roomsNoPacksBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.l10n.cancel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  AppRouter.router.go(RouteNames.marketplace);
                },
                child: Text(context.l10n.roomsBrowsePacks),
              ),
            ],
          ),
        );
        return;
      }
    }

    final isPremium =
        context.read<AuthProvider>().currentUser?.isPremium ?? false;
    // Limit values are admin-configurable (app_settings), never hardcoded
    // here — this is a UX pre-check only; create_room() re-enforces the
    // same limits (daily count + minimum-hours gate + the global
    // enable/disable switch) server-side regardless of what this returns.
    final platformConfig = context.read<PlatformConfigProvider>();
    final dailyLimit = platformConfig.roomCreationDailyLimit(
      isPremium: isPremium,
    );
    final status = await sl.roomRepository.getRoomCreationStatus();
    if (status.hasHitDailyLimit) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.roomsDailyLimitTitle),
          content: Text(
            isPremium
                ? context.l10n.roomsDailyLimitPremiumBody(dailyLimit)
                : context.l10n.roomsDailyLimitFreeBody(
                    dailyLimit,
                    platformConfig.roomCreationDailyLimit(isPremium: true),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.ok),
            ),
          ],
        ),
      );
      return;
    }
    if (status.isTooSoon) {
      if (!mounted) return;
      final remaining = status.nextAllowedAt!.difference(DateTime.now());
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes.remainder(60);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.roomsCreationTooSoonTitle),
          content: Text(context.l10n.roomsCreationTooSoonBody(hours, minutes)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.ok),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    final room = await showModalBottomSheet<RoomEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateRoomSheet(),
    );
    if (room != null && mounted) {
      AppRouter.router.push('/home/room/${room.id}');
      if (room.visibility == RoomVisibility.public) {
        sl.roomRepository.notifyFriendsRoomCreated(room.id).catchError((_) {});
      }
    }
  }

  Future<void> _enterRoom(String targetRoomId) async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    final active = await sl.roomRepository.getActiveMembership(userId);

    if (active == null || active['room_id'] == targetRoomId) {
      if (mounted) AppRouter.router.push('/home/room/$targetRoomId');
      return;
    }

    if (!mounted) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.roomsAlreadyInRoomTitle),
        content: Text(context.l10n.roomsAlreadyInRoomBody(active['room_name'])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: Text(context.l10n.cancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, 'return'),
            child: Text(context.l10n.roomsReturnToMyRoom),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, 'leave'),
            child: Text(context.l10n.roomsLeaveForGood),
          ),
        ],
      ),
    );

    if (choice == null || choice == 'cancel' || !mounted) return;

    if (choice == 'return') {
      AppRouter.router.push('/home/room/${active['room_id']}');
      return;
    }

    final oldRoomId = active['room_id'] as String;
    final wasOwner = active['is_owner'] == true;
    final wasActive = active['status'] != 'waiting';

    await sl.roomRepository.forceLeaveRoom(userId: userId, roomId: oldRoomId);

    if (wasOwner) {
      try {
        if (wasActive) {
          await sl.realtimeService.broadcastGameEnded(oldRoomId, {
            'reason': 'host_left',
          });
        }
        await sl.realtimeService.broadcastRoomEvent(oldRoomId, {
          'type': 'owner_left',
          'reason': 'host_left',
        });
      } catch (_) {}
    }

    if (mounted) AppRouter.router.push('/home/room/$targetRoomId');
  }

  Future<void> _joinByCode() async {
    final room = await showDialog<RoomEntity>(
      context: context,
      builder: (_) => const JoinCodeDialog(),
    );
    if (room != null && mounted) {
      await _enterRoom(room.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final isPremium =
        context.watch<AuthProvider>().currentUser?.isPremiumActive ?? false;

    return ScreenTutorial(
      tutorialId: TutorialIds.roomBrowserIntro,
      steps: [_createFabKey, _joinCodeKey, _filterKey],
      // Wait until the first-launch "main sections" tour is done so the two
      // never play at once (this screen is Home's first tab).
      enabled: sl.tutorialService.isCompleted(TutorialIds.homeIntro),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              floating: true,
              snap: true,
              title: Text(l10n.roomsTitle),
              actions: [
                Consumer<NotificationProvider>(
                  builder: (_, notifs, __) => IconButton(
                    onPressed: () =>
                        AppRouter.router.push(RouteNames.notifications),
                    icon: Badge(
                      isLabelVisible: notifs.unreadCount > 0,
                      label: Text('${notifs.unreadCount}'),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    tooltip: context.l10n.settingsNotifications,
                  ),
                ),
                if (isPremium)
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClosedRoomsScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.history_rounded),
                    tooltip: context.l10n.roomsMyClosedRooms,
                  ),
                tutorialShowcase(
                  context: context,
                  showcaseKey: _joinCodeKey,
                  title: l10n.tutBrowserJoinCodeTitle,
                  description: l10n.tutBrowserJoinCodeBody,
                  child: IconButton(
                    onPressed: _joinByCode,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    tooltip: l10n.roomsJoinCode,
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: tutorialShowcase(
                  context: context,
                  showcaseKey: _filterKey,
                  title: l10n.tutBrowserFilterTitle,
                  description: l10n.tutBrowserFilterBody,
                  child: _GameTypeFilterBar(
                    selected: _gameTypeFilter,
                    onChanged: (f) {
                      setState(() => _gameTypeFilter = f);
                      _loadRooms();
                    },
                  ),
                ),
              ),
            ),
          ],
          body: Column(
            children: [
              // Sourced from PackProvider.promotedPacks, already loaded
              // app-wide at login (same data the marketplace's Featured tab
              // shows) — no extra network call on this screen and no effect
              // on the room list's own pagination below.
              Consumer<PackProvider>(
                builder: (_, packs, __) => packs.promotedPacks.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PromotedPacksCarousel(
                          packs: packs.promotedPacks,
                        ),
                      ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadRooms,
                  child: _buildBody(theme, l10n),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: tutorialShowcase(
          context: context,
          showcaseKey: _createFabKey,
          title: l10n.tutBrowserCreateTitle,
          description: l10n.tutBrowserCreateBody,
          child: FloatingActionButton.extended(
            heroTag: 'room_browser_create_fab',
            onPressed: _isCreating ? null : _createRoom,
            icon: _isCreating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add_rounded),
            label: Text(l10n.roomsCreate),
            backgroundColor: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, dynamic l10n) {
    if (_isLoading) {
      return _LoadingGrid();
    }
    if (_hasError) {
      return ErrorView(
        message: context.l10n.errorUnexpected,
        onRetry: _loadRooms,
      );
    }
    if (_rooms.isEmpty) {
      return JEmptyState(
        emoji: '🚪',
        title: l10n.roomsEmpty,
        subtitle: l10n.roomsEmptySubtitle,
        action: FilledButton.icon(
          onPressed: _createRoom,
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.roomsCreate),
        ),
      );
    }
    return ListView.separated(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: _rooms.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i >= _rooms.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return RoomCard(
          key: ValueKey(_rooms[i].id),
          room: _rooms[i],
          onTap: () => _enterRoom(_rooms[i].id),
        ).animate(delay: (i * 35).ms).fadeIn().slideY(begin: 0.06, end: 0);
      },
    );
  }
}

class _GameTypeFilterBar extends StatelessWidget {
  const _GameTypeFilterBar({required this.selected, required this.onChanged});
  final String? selected;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filters = [
      (null, l10n.gameNameAll, '🎮'),
      ('truth_or_dare', l10n.gameNameTruthOrDare, '🎯'),
      ('never_have_i_ever', l10n.gameNameNeverHaveIEver, '🍹'),
      ('meme_game', l10n.gameNameMeme, '😂'),
    ];

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        children: filters.map((f) {
          final isSelected = selected == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${f.$3} ${f.$2}'),
              selected: isSelected,
              onSelected: (_) => onChanged(isSelected ? null : f.$1),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        4,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerBox(width: double.infinity, height: 88, radius: 16),
        ).animate(delay: (i * 60).ms).fadeIn(),
      ),
    );
  }
}
