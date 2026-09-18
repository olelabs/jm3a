import 'package:flutter/cupertino.dart';
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
import '../widgets/navigation/jma3a_bottom_nav_bar.dart';
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
  static const _packsTabIndex = 2;
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

    // A Store-granted pack notification arrived (NotificationProvider's own
    // CDC subscription on the notifications table — no separate Realtime
    // channel added here) while the app stays open on whatever screen the
    // user is currently viewing. Refreshing PackProvider's entitlement
    // state here — the one place already coordinating cross-provider
    // reactions (see _refreshAll) — makes the newly granted pack available
    // in Packs and the room pack selector without an app restart or
    // closing/reopening an unrelated screen. Same "watch + post-frame
    // consume" shape as the streak dialog above.
    if (context.watch<NotificationProvider>().pendingEntitlementNotification !=
        null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final notificationProvider = context.read<NotificationProvider>();
        if (notificationProvider.pendingEntitlementNotification == null) {
          return;
        }
        notificationProvider.consumeEntitlementNotification();
        context.read<PackProvider>().refreshEntitlements();
      });
    }

    return ScreenTutorial(
      tutorialId: TutorialIds.homeIntro,
      steps: [_navShowcaseKey],
      child: Scaffold(
        // Jma3aBottomNavBar is a floating, translucent glass control, not
        // an opaque bar — without extendBody, Scaffold would reserve its
        // full-width bounding box as body-free space and paint
        // scaffoldBackgroundColor there instead, which is exactly the
        // flat "panel behind the glass" look this was meant to avoid.
        // With it, PlayfulBackground/page content runs underneath the
        // whole floating control, visible through its blur and through
        // the transparent margins around it.
        extendBody: true,
        body: PlayfulBackground(
          // The navbar is a true floating OVERLAY, not part of the
          // layout — IndexedStack (and so every nested Scaffold/page)
          // gets the FULL, un-shrunk body height, so their scrollable
          // content's viewport genuinely extends behind the bar and can
          // show through its glass while scrolling. A Padding here would
          // instead clip that viewport short of the true bottom edge,
          // making it impossible for content to ever appear behind the
          // bar at all.
          //
          // Two separate, page-owned concerns build on top of that full
          // height, both driven by the same Jma3aBottomNavBar.overlayInset:
          // each page gives its own FloatingActionButton (if any) a
          // floatingActionButtonLocation: Jma3aBottomNavBar.fabLocation(
          // context), and gives its own scrollable a trailing bottom
          // inset — see e.g. RoomBrowserScreen. Neither can be done here
          // centrally: a FAB's location and a ScrollView's padding are
          // both properties of the page that owns them, not of this
          // shell, and — critically — this shell must NOT inject its own
          // MediaQuery override for this, because Scaffold(extendBody:
          // true) already adjusts the ambient MediaQuery.padding to
          // account for this bar's height; stacking another override on
          // top of that here previously double-counted the bar's own
          // footprint (see overlayInset's own doc comment).
          child: IndexedStack(index: _index, children: _pages),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The "Developed by MOUJ TECH" mark previously shown here for the
            // Rooms Browse (index 0) and Packs/Marketplace (index 2) tabs has
            // been deliberately removed from this shared nav bar — those two
            // screens should not carry developer branding. MoujTechBrand
            // itself is untouched and still used elsewhere (Settings, About,
            // auth screens, Splash).
            tutorialShowcase(
              context: context,
              showcaseKey: _navShowcaseKey,
              title: context.l10n.tutHomeNavTitle,
              description: context.l10n.tutHomeNavBody,
              child: Jma3aBottomNavBar(
                selectedIndex: _index,
                onDestinationSelected: (i) {
                  // Profile and Packs both persist in the IndexedStack rather
                  // than being pushed/popped as their own routes, so tab
                  // switches never reach RouteObserver/didPopNext — this is
                  // the one signal available for "this tab was reopened".
                  // Reuses the existing tab-switch callback rather than
                  // adding a separate visibility-detection mechanism.
                  //
                  // Packs specifically: a Store-granted (or otherwise
                  // server-side) entitlement change has no other way to
                  // reach the already-built MarketplaceScreen — its
                  // initState only ever runs once per app session under
                  // IndexedStack, so without this, a newly granted pack
                  // would stay invisible in Browse until the app is
                  // backgrounded/resumed or the user logs out/in.
                  final enteringProfile = i == _profileTabIndex && _index != i;
                  final enteringPacks = i == _packsTabIndex && _index != i;
                  setState(() => _index = i);
                  if (enteringProfile) {
                    context.read<ProfileProvider>().refreshAll();
                  }
                  if (enteringPacks) {
                    context.read<PackProvider>().refreshEntitlements();
                  }
                },
                destinations: [
                  Jma3aNavDestination(
                    icon: Icons.meeting_room_outlined,
                    selectedIcon: Icons.meeting_room_rounded,
                    cupertinoIcon: CupertinoIcons.square_grid_2x2,
                    cupertinoSelectedIcon: CupertinoIcons.square_grid_2x2_fill,
                    label: l10n.navRooms,
                  ),
                  Jma3aNavDestination(
                    icon: Icons.people_outline_rounded,
                    selectedIcon: Icons.people_rounded,
                    cupertinoIcon: CupertinoIcons.person_2,
                    cupertinoSelectedIcon: CupertinoIcons.person_2_fill,
                    label: l10n.navFriends,
                    badgeCount: friendCount,
                  ),
                  Jma3aNavDestination(
                    icon: Icons.storefront_outlined,
                    selectedIcon: Icons.storefront_rounded,
                    cupertinoIcon: CupertinoIcons.bag,
                    cupertinoSelectedIcon: CupertinoIcons.bag_fill,
                    label: l10n.navMarketplace,
                  ),
                  Jma3aNavDestination(
                    icon: Icons.account_circle_outlined,
                    selectedIcon: Icons.account_circle_rounded,
                    cupertinoIcon: CupertinoIcons.person_crop_circle,
                    cupertinoSelectedIcon:
                        CupertinoIcons.person_crop_circle_fill,
                    label: l10n.navProfile,
                    // The Profile destination must never carry the
                    // notification-count badge (unlike Friends' pending-
                    // request badge above) — notifications remain fully
                    // intact and are still shown wherever they're
                    // legitimately surfaced (the Notifications screen
                    // itself, etc.); this destination simply no longer
                    // mirrors that count. No badgeCount passed here at all
                    // (defaults to 0), matching Rooms/Marketplace above.
                    selectedIconOverride: !isPremium
                        ? null
                        : (isIOS) => ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFF5A623), Color(0xFFFF6B35)],
                            ).createShader(bounds),
                            child: Icon(
                              isIOS
                                  ? CupertinoIcons.person_crop_circle_fill
                                  : Icons.account_circle_rounded,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
