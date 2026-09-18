import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/platform_config_provider.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../../../games/engine/base_game_engine.dart';
import '../pack_provider.dart';
import '../widgets/pack_card_widget.dart';
import '../widgets/promoted_packs_carousel.dart';
import '../../../../shared/widgets/navigation/jma3a_bottom_nav_bar.dart';
import 'my_packs_screen.dart';
import 'physical_pack_requests_screen.dart';

export '../widgets/pack_card_widget.dart' show PackCard;

/// Marketplace home — 3 tabs: Browse, Featured, My Packs.
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Not late final — Featured is hidden entirely when there are no
  // featured packs (task requirement, not just an empty-state message),
  // and TabController's length can't change in place, so the tab count
  // toggling requires disposing and recreating it. See _ensureTabController.
  TabController? _tabs;
  bool _hasFeatured = false;
  GameType? _gameTypeFilter;
  String? _categoryFilter;
  final _scrollCtrl = ScrollController();

  bool _searchMode = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    // A pack can be granted entirely server-side (an approved Jma3a Store
    // order) with nothing in a running session to notice it. Re-reading
    // entitlements when this screen opens, and again whenever the app
    // comes back to the foreground, is what makes such a pack appear
    // without a logout/login.
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PackProvider>().refreshEntitlements();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<PackProvider>().refreshEntitlements();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabs?.dispose();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Featured must be completely hidden (not just an empty-state message)
  /// when there are no featured packs — TabController's length is fixed
  /// once created, so toggling that requires disposing the old controller
  /// and creating a new one. This only actually runs when [hasFeatured]
  /// changes (rare — driven by data loading/ownership, not user taps), so
  /// resetting to Browse (index 0) on a real transition is simpler and
  /// safer than trying to remap a selected index across a tab-count change,
  /// and never surprises a mid-swipe user since it isn't tap-driven.
  void _ensureTabController(bool hasFeatured) {
    if (_tabs != null && hasFeatured == _hasFeatured) return;
    _tabs?.dispose();
    _hasFeatured = hasFeatured;
    _tabs = TabController(length: hasFeatured ? 3 : 2, vsync: this);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels <
        _scrollCtrl.position.maxScrollExtent - 200) {
      return;
    }
    if (_searchMode) {
      context.read<PackProvider>().loadMoreSearchResults(
        gameType: _gameTypeFilter?.toDbString(),
        categoryId: _categoryFilter,
      );
    } else {
      context.read<PackProvider>().loadMoreBrowsePacks(
        gameType: _gameTypeFilter?.toDbString(),
        categoryId: _categoryFilter,
      );
    }
  }

  void _runSearch(String query) {
    context.read<PackProvider>().search(
      query,
      gameType: _gameTypeFilter?.toDbString(),
      categoryId: _categoryFilter,
    );
  }

  void _enterSearchMode() {
    setState(() => _searchMode = true);
    // Post-frame: the TextField this focuses doesn't exist in the tree
    // until the setState above rebuilds it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _exitSearchMode() {
    setState(() => _searchMode = false);
    _searchCtrl.clear();
    context.read<PackProvider>().clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isVerified = user?.isVerifiedCreator ?? false;
    // Reactive: featuredPacks is itself a computed (featured AND
    // free-or-owned) getter, so this automatically re-evaluates whenever
    // entitlements refresh, not just on first load.
    final hasFeatured = context.watch<PackProvider>().featuredPacks.isNotEmpty;
    _ensureTabController(hasFeatured);
    final tabs = _tabs!;

    return Scaffold(
      // Transparent so HomeShellScreen's PlayfulBackground (the premium
      // animated theme effect) shows through uninterrupted, all the way
      // to the floating bottom nav bar — matching RoomBrowserScreen's
      // identical, already-correct setting.
      backgroundColor: Colors.transparent,
      // Precise ~3px clearance above the floating navbar — see
      // Jma3aBottomNavBar.fabLocation's own doc comment for why
      // Scaffold's default FAB locations can't hit that tight a gap.
      floatingActionButtonLocation: Jma3aBottomNavBar.fabLocation(context),
      floatingActionButton: isVerified
          ? FloatingActionButton.extended(
              heroTag: 'marketplace_create_pack_fab',
              onPressed: () => context.push('/creator'),
              icon: const Icon(Icons.add_rounded),
              label: Text(context.l10n.packCreatePack),
            )
          : null,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            floating: true,
            snap: true,
            automaticallyImplyLeading: false,
            title: _searchMode
                ? TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    autofocus: true,
                    onChanged: _runSearch,
                    decoration: InputDecoration(
                      hintText: context.l10n.packSearchHint,
                      border: InputBorder.none,
                    ),
                  )
                : Text(context.l10n.navMarketplace),
            leading: _searchMode
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: _exitSearchMode,
                  )
                : null,
            actions: _searchMode
                ? [
                    // ValueListenableBuilder (not a bare text-length
                    // check) because _MarketplaceScreenState doesn't
                    // setState per keystroke — only PackProvider gets
                    // notified — so this needs its own listener on the
                    // controller to show/hide reactively as the user
                    // types.
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchCtrl,
                      builder: (_, value, _) => value.text.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                _runSearch('');
                              },
                            ),
                    ),
                  ]
                : [
                    // Phase 4B (physical pack requests flag) — same
                    // PlatformConfigProvider field pack_detail_screen.dart
                    // already gates its own "Request Physical Copy" button
                    // with, so both entry points stay in sync under one
                    // shared flag read rather than a second one.
                    if (context
                        .watch<PlatformConfigProvider>()
                        .physicalPackRequestsEnabled)
                      IconButton(
                        icon: const Icon(Icons.local_shipping_outlined),
                        tooltip: context.l10n.packMyPhysicalRequests,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PhysicalPackRequestsScreen(),
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.search_rounded),
                      onPressed: _enterSearchMode,
                      tooltip: context.l10n.searchLabel,
                    ),
                  ],
            bottom: _searchMode
                ? null
                : TabBar(
                    controller: tabs,
                    tabs: [
                      Tab(text: context.l10n.packTabBrowse),
                      if (hasFeatured) Tab(text: context.l10n.packTabFeatured),
                      Tab(text: context.l10n.packTabMyPacks),
                    ],
                  ),
          ),
        ],
        body: _searchMode
            ? _SearchResultsView(scrollCtrl: _scrollCtrl)
            : TabBarView(
                controller: tabs,
                children: [
                  _BrowseTab(
                    scrollCtrl: _scrollCtrl,
                    gameTypeFilter: _gameTypeFilter,
                    categoryFilter: _categoryFilter,
                    // Every filter callback re-sends the FULL current
                    // filter set, not just the field it owns — otherwise
                    // changing one silently drops the others.
                    onGameTypeChanged: (gt) {
                      setState(() => _gameTypeFilter = gt);
                      context.read<PackProvider>().loadBrowsePacks(
                        reset: true,
                        gameType: gt?.toDbString(),
                        categoryId: _categoryFilter,
                      );
                    },
                  ),
                  if (hasFeatured) const _FeaturedTab(),
                  const MyPacksScreen(),
                ],
              ),
      ),
    );
  }
}

// ── Search results ───────────────────────────────────────────────────────────
class _SearchResultsView extends StatelessWidget {
  const _SearchResultsView({required this.scrollCtrl});
  final ScrollController scrollCtrl;

  @override
  Widget build(BuildContext context) {
    return Consumer<PackProvider>(
      builder: (ctx, packs, _) {
        // Reads the query back from PackProvider (updated inside
        // search() before it notifies) rather than the TextField's own
        // controller — this widget only rebuilds on PackProvider
        // notifications, and the parent MarketplaceScreen doesn't
        // setState per keystroke, so a locally-threaded controller.text
        // would lag a keystroke behind.
        if (packs.searchQuery.trim().length < 2) {
          return _EmptySearchState(
            emoji: '🔍',
            title: ctx.l10n.packSearchForPacks,
            subtitle: ctx.l10n.packSearchMinChars,
          );
        }
        if (packs.isSearching && packs.searchResults.isEmpty) {
          return _PackGridShimmer();
        }
        if (packs.searchResults.isEmpty) {
          return _EmptySearchState(
            emoji: '🔍',
            title: ctx.l10n.packNoPacksFound,
            subtitle: ctx.l10n.packSearchNoResultsHint,
          );
        }
        return CustomScrollView(
          controller: scrollCtrl,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => PackCard(
                    pack: packs.searchResults[i],
                    isOwned: packs.isOwned(packs.searchResults[i]),
                    onTap: () => AppRouter.router.push(
                      '${RouteNames.marketplace}/pack/${packs.searchResults[i].id}',
                    ),
                  ).animate(delay: (i * 25).ms).fadeIn(),
                  childCount: packs.searchResults.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
              ),
            ),
            if (packs.isLoadingMoreSearch)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            // Trailing spacer so the last row can be scrolled fully
            // above the floating navbar instead of stopping at its
            // visual top edge.
            SliverToBoxAdapter(
              child: SizedBox(height: Jma3aBottomNavBar.overlayInset(context)),
            ),
          ],
        );
      },
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Browse tab ────────────────────────────────────────────────────────────────
class _BrowseTab extends StatelessWidget {
  const _BrowseTab({
    required this.scrollCtrl,
    required this.gameTypeFilter,
    required this.categoryFilter,
    required this.onGameTypeChanged,
  });

  final ScrollController scrollCtrl;
  final GameType? gameTypeFilter;
  final String? categoryFilter;
  final void Function(GameType?) onGameTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Consumer<PackProvider>(
      builder: (ctx, packs, _) {
        if (packs.isLoading && packs.browsePacks.isEmpty) {
          return _PackGridShimmer();
        }
        if (packs.failure != null && packs.browsePacks.isEmpty) {
          return ErrorView(
            message: ctx.l10n.errorUnexpected,
            onRetry: () => packs.loadBrowsePacks(reset: true),
          );
        }

        return RefreshIndicator(
          onRefresh: () => packs.loadBrowsePacks(reset: true),
          child: CustomScrollView(
            controller: scrollCtrl,
            slivers: [
              // Filter row
              SliverToBoxAdapter(
                child: _FilterRow(
                  selected: gameTypeFilter,
                  onTypeChanged: onGameTypeChanged,
                ),
              ),

              if (packs.browsePacks.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      ctx.l10n.packNoPacksFound,
                      style: ctx.textTheme.bodyMedium?.copyWith(
                        color: ctx.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) =>
                          PackCard(
                                pack: packs.browsePacks[i],
                                isOwned: packs.isOwned(packs.browsePacks[i]),
                                onTap: () => AppRouter.router.push(
                                  '${RouteNames.marketplace}/pack/${packs.browsePacks[i].id}',
                                ),
                              )
                              .animate(delay: (i * 25).ms)
                              .fadeIn()
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1, 1),
                              ),
                      childCount: packs.browsePacks.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.68,
                        ),
                  ),
                ),
                if (packs.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                // Trailing spacer so the last row can be scrolled fully
                // above the floating navbar instead of stopping at its
                // visual top edge.
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: Jma3aBottomNavBar.overlayInset(context),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Phase 4A (packs localization) — the localized display label for a
/// game-type filter chip. Extracted as a pure function (not inlined in
/// _FilterRow's build) so it's independently unit-testable per locale
/// without pumping a widget, matching this repo's established pattern
/// for extracting decision logic. Matches the SAME
/// context.l10n.gameName* keys already used identically elsewhere for
/// this exact "short label" use case (e.g. room_share_card.dart,
/// room_browser_screen.dart, game_settings_sheet.dart) — never
/// GameType.displayName (base_game_engine.dart), which is hardcoded
/// English and was the actual bug here. Database/internal identifiers
/// (GameType.toDbString()) are completely unrelated and untouched.
String gameTypeFilterLabel(AppLocalizations l10n, GameType gt) => switch (gt) {
  GameType.truthOrDare => l10n.gameNameTruthOrDare,
  GameType.neverHaveIEver => l10n.gameNameNeverHaveIEver,
  GameType.memeGame => l10n.gameNameMeme,
};

/// Game-type filters only. There is deliberately no "Free" chip: the list
/// itself now contains only packs the user can actually use (free ones and
/// ones they own), so a free/paid split has nothing left to narrow.
class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selected,
    required this.onTypeChanged,
  });

  final GameType? selected;
  final void Function(GameType?) onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _FilterChip(
            label: context.l10n.gameNameAll,
            isSelected: selected == null,
            onTap: () => onTypeChanged(null),
          ),
          const SizedBox(width: 8),
          ...GameType.values.map(
            (gt) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: gameTypeFilterLabel(context.l10n, gt),
                isSelected: selected == gt,
                onTap: () => onTypeChanged(selected == gt ? null : gt),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colorScheme.primary
              : context.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? context.colorScheme.onPrimary
                    : context.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? context.colorScheme.onPrimary
                    : context.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Featured tab ──────────────────────────────────────────────────────────────
class _FeaturedTab extends StatelessWidget {
  const _FeaturedTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<PackProvider>(
      builder: (ctx, packs, _) {
        final featured = packs.featuredPacks;
        final promoted = packs.promotedPacks;

        return RefreshIndicator(
          onRefresh: () async {},
          child: CustomScrollView(
            slivers: [
              // Promoted banner
              if (promoted.isNotEmpty)
                SliverToBoxAdapter(
                  child: PromotedPacksCarousel(packs: promoted),
                ),

              // Featured grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Text(
                        ctx.l10n.packFeaturedHeading,
                        style: ctx.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (featured.isEmpty && !packs.isLoading)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      ctx.l10n.packNoFeaturedPacksYet,
                      style: ctx.textTheme.bodyMedium?.copyWith(
                        color: ctx.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => PackCard(
                        pack: featured[i],
                        isOwned: packs.isOwned(featured[i]),
                        onTap: () => AppRouter.router.push(
                          '${RouteNames.marketplace}/pack/${featured[i].id}',
                        ),
                      ).animate(delay: (i * 30).ms).fadeIn(),
                      childCount: featured.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.68,
                        ),
                  ),
                ),
              // Trailing spacer so the last row can be scrolled fully
              // above the floating navbar instead of stopping at its
              // visual top edge.
              SliverToBoxAdapter(
                child: SizedBox(
                  height: Jma3aBottomNavBar.overlayInset(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PackGridShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: 6,
      itemBuilder: (_, __) =>
          ShimmerBox(width: double.infinity, height: double.infinity),
    );
  }
}
