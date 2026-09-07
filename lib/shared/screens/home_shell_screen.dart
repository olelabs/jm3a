
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/service_locator.dart';
import '../../core/extensions/context_ext.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/app_theme_service.dart';
import '../../core/services/app_tutorial_service.dart';
import '../widgets/tutorial/screen_tutorial.dart';
import '../../features/friends/presentation/friends_provider.dart';
import '../../features/notifications/presentation/notification_provider.dart';
import '../../features/packs/presentation/pack_provider.dart';
import '../../features/profile/presentation/profile_provider.dart';
import '../../features/wallet/presentation/wallet_provider.dart';
import '../widgets/streak_achievement_dialog.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_names.dart';
import '../../features/rooms/presentation/screens/room_browser_screen.dart';
import '../../shared/widgets/playful_background.dart';
import '../../features/friends/presentation/screens/friends_screen.dart';
import '../../features/packs/presentation/screens/marketplace_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _index = 0;

  // First-launch "these are your main sections" highlight on the bottom nav.
  final GlobalKey _navShowcaseKey = GlobalKey();

  static const _pages = [
    RoomBrowserScreen(),
    FriendsScreen(),
    MarketplaceScreen(),
    ProfileScreen(),
  ];
  static const _profileTabIndex = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
      _checkActiveGameMembership();
    });
  }

  void _refreshAll() {
    final uid = context.read<PackProvider>().currentUserId;
    if (uid == null) return;

    context.read<PackProvider>().onAuthChanged(uid);
    context.read<FriendsProvider>().onAuthChanged(uid);
    context.read<WalletProvider>().onAuthChanged(uid);

    sl.notificationService.setExternalUserId(uid);
  }

  bool _checkedActiveGameMembership = false;

  /// Landing on Home right after login/launch while still an intact member
  /// of a room whose game is already running is the common "app was just
  /// backgrounded or restarted mid-game" case — route straight back to the
  /// lobby (which shows the in-progress-game banner) instead of leaving the
  /// player stranded on Home with no obvious way back in. Checked once per
  /// screen lifetime, not on every rebuild.
  Future<void> _checkActiveGameMembership() async {
    if (_checkedActiveGameMembership) return;
    _checkedActiveGameMembership = true;
    final uid = context.read<AuthProvider>().currentUser?.id;
    if (uid == null) return;
    try {
      final membership = await sl.roomRepository.getActiveMembership(uid);
      if (!mounted || membership == null) return;
      final status = membership['status'] as String?;
      if (status != 'in_game' && status != 'paused') return;
      final roomId = membership['room_id'] as String?;
      if (roomId == null) return;
      AppRouter.router.push('${RouteNames.home}/room/$roomId');
    } catch (_) {
      // Non-fatal — the room is still reachable manually via Room Browser.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notifCount = context.watch<NotificationProvider>().unreadCount;
    final friendCount = context.watch<FriendsProvider>().pendingCount;
    final isPremium =
        context.watch<AuthProvider>().currentUser?.isPremiumActive ?? false;

    // Streak congratulations correction pass — fires post-frame so it
    // never shows mid-build, and only the FIRST callback among any that
    // get scheduled in the same frame batch actually finds a non-null
    // event (it consumes it as its first action; a re-read inside a
    // later callback in the same batch already sees null and no-ops) —
    // see ProfileProvider.pendingStreakAchievement's own comment.
    if (context.watch<ProfileProvider>().pendingStreakAchievement != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final profileProvider = context.read<ProfileProvider>();
        final event = profileProvider.pendingStreakAchievement;
        if (event == null) return;
        profileProvider.consumeStreakAchievement();
        showStreakAchievementDialog(context, event);
      });
    }

    return ScreenTutorial(
      tutorialId: TutorialIds.homeIntro,
      steps: [_navShowcaseKey],
      child: Scaffold(
      body: PlayfulBackground(
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: tutorialShowcase(
        context: context,
        showcaseKey: _navShowcaseKey,
        title: context.l10n.tutHomeNavTitle,
        description: context.l10n.tutHomeNavBody,
        child: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          // Profile persists in the IndexedStack rather than being
          // pushed/popped as its own route, so tab switches never reach
          // RouteObserver/didPopNext (see ProfileScreen) — this is the
          // one signal available for "the Profile tab was reopened".
          // Reuses the existing tab-switch callback rather than adding a
          // separate visibility-detection mechanism.
          final enteringProfile = i == _profileTabIndex && _index != i;
          setState(() => _index = i);
          if (enteringProfile) {
            context.read<ProfileProvider>().refreshAll();
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.meeting_room_outlined),
            selectedIcon: const Icon(Icons.meeting_room_rounded),
            label: l10n.navRooms,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: friendCount > 0,
              label: Text('$friendCount'),
              child: const Icon(Icons.people_outline_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: friendCount > 0,
              label: Text('$friendCount'),
              child: const Icon(Icons.people_rounded),
            ),
            label: l10n.navFriends,
          ),
          NavigationDestination(
            icon: const Icon(Icons.store_outlined),
            selectedIcon: const Icon(Icons.store_rounded),
            label: l10n.navMarketplace,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: notifCount > 0,
              label: Text('$notifCount'),
              child: const Icon(Icons.person_outline_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: notifCount > 0,
              label: Text('$notifCount'),
              child: isPremium
                  ? ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFF5A623), Color(0xFFFF6B35)],
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_rounded),
            ),
            label: l10n.navProfile,
          ),
        ],
        ),
      ),
      ),
    );
  }
}
