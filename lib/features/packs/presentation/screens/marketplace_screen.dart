import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../../../games/engine/base_game_engine.dart';
import '../pack_provider.dart';
import '../widgets/pack_card_widget.dart';
import '../widgets/promoted_packs_carousel.dart';
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
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  GameType? _gameTypeFilter;
  String? _categoryFilter;
  bool _freeOnly = false;
  final _scrollCtrl = ScrollController();

  bool _searchMode = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
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
        freeOnly: _freeOnly,
      );
    } else {
      context.read<PackProvider>().loadMoreBrowsePacks(
        gameType: _gameTypeFilter?.toDbString(),
        categoryId: _categoryFilter,
        freeOnly: _freeOnly,
      );
    }
  }

  void _runSearch(String query) {
    context.read<PackProvider>().search(
      query,
      gameType: _gameTypeFilter?.toDbString(),
      categoryId: _categoryFilter,
      freeOnly: _freeOnly,
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

    return Scaffold(
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
                    controller: _tabs,
                    tabs: [
                      Tab(text: context.l10n.packTabBrowse),
                      Tab(text: context.l10n.packTabFeatured),
                      Tab(text: context.l10n.packTabMyPacks),
                    ],
                  ),
          ),
        ],
        body: _searchMode
            ? _SearchResultsView(scrollCtrl: _scrollCtrl)
            : TabBarView(
                controller: _tabs,
                children: [
                  _BrowseTab(
                    scrollCtrl: _scrollCtrl,
                    gameTypeFilter: _gameTypeFilter,
                    categoryFilter: _categoryFilter,
                    freeOnly: _freeOnly,
                    // Item 2 fix — filters must combine as AND, not each
                    // reset the others: selecting Free then Truth or Dare
                    // (or vice versa) used to only pass the filter that
                    // JUST changed, silently dropping whichever one was
                    // already active (loadBrowsePacks defaults freeOnly
                    // to false / gameType to null when omitted) — e.g.
                    // "Free" then "Truth or Dare" showed ALL Truth or
                    // Dare packs, paid included, because the second call
                    // never re-passed freeOnly: true. Every filter
                    // callback now re-sends the FULL current filter set
                    // (this screen's own _gameTypeFilter/_categoryFilter/
                    // _freeOnly state), not just the one field it itself
                    // owns.
                    onGameTypeChanged: (gt) {
                      setState(() => _gameTypeFilter = gt);
                      context.read<PackProvider>().loadBrowsePacks(
                        reset: true,
                        gameType: gt?.toDbString(),
                        categoryId: _categoryFilter,
                        freeOnly: _freeOnly,
                      );
                    },
                    onFreeOnlyChanged: (v) {
                      setState(() => _freeOnly = v);
                      context.read<PackProvider>().loadBrowsePacks(
                        reset: true,
                        gameType: _gameTypeFilter?.toDbString(),
                        categoryId: _categoryFilter,
                        freeOnly: v,
                      );
                    },
                  ),
                  const _FeaturedTab(),
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
    required this.freeOnly,
    required this.onGameTypeChanged,
    required this.onFreeOnlyChanged,
  });

  final ScrollController scrollCtrl;
  final GameType? gameTypeFilter;
  final String? categoryFilter;
  final bool freeOnly;
  final void Function(GameType?) onGameTypeChanged;
  final void Function(bool) onFreeOnlyChanged;

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
                  freeOnly: freeOnly,
                  onTypeChanged: onGameTypeChanged,
                  onFreeOnlyChanged: onFreeOnlyChanged,
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selected,
    required this.freeOnly,
    required this.onTypeChanged,
    required this.onFreeOnlyChanged,
  });

  final GameType? selected;
  final bool freeOnly;
  final void Function(GameType?) onTypeChanged;
  final void Function(bool) onFreeOnlyChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _FilterChip(
            label: context.l10n.gameNameAll,
            isSelected: selected == null && !freeOnly,
            onTap: () {
              onTypeChanged(null);
              onFreeOnlyChanged(false);
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: context.l10n.packFreeLabel,
            isSelected: freeOnly,
            onTap: () => onFreeOnlyChanged(!freeOnly),
            icon: Icons.redeem_rounded,
          ),
          const SizedBox(width: 8),
          ...GameType.values.map(
            (gt) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: gt.displayName,
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
                SliverToBoxAdapter(child: PromotedPacksCarousel(packs: promoted)),

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
