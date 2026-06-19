import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../../../games/engine/base_game_engine.dart';
import '../../domain/pack_entity.dart';
import '../pack_provider.dart';
import '../widgets/pack_card_widget.dart';
import '../widgets/pack_download_button.dart';
import 'my_packs_screen.dart';

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
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<PackProvider>().loadMoreBrowsePacks(
        gameType: _gameTypeFilter?.toDbString(),
      );
    }
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
              label: const Text('Create Pack'),
            )
          : null,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Text(context.l10n.navMarketplace),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {}, // search screen TODO
                tooltip: 'Search',
              ),
            ],
            bottom: TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Browse'),
                Tab(text: 'Featured'),
                Tab(text: 'My Packs'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _BrowseTab(
              scrollCtrl: _scrollCtrl,
              gameTypeFilter: _gameTypeFilter,
              categoryFilter: _categoryFilter,
              freeOnly: _freeOnly,
              onGameTypeChanged: (gt) {
                setState(() => _gameTypeFilter = gt);
                context.read<PackProvider>().loadBrowsePacks(
                  reset: true,
                  gameType: gt?.toDbString(),
                );
              },
              onFreeOnlyChanged: (v) {
                setState(() => _freeOnly = v);
                context.read<PackProvider>().loadBrowsePacks(
                  reset: true,
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
                      'No packs found',
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
            label: 'All',
            isSelected: selected == null && !freeOnly,
            onTap: () {
              onTypeChanged(null);
              onFreeOnlyChanged(false);
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Free',
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
                SliverToBoxAdapter(child: _PromotedBanner(packs: promoted)),

              // Featured grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Text(
                        '⭐ Featured',
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
                      'No featured packs yet',
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

class _PromotedBanner extends StatelessWidget {
  const _PromotedBanner({required this.packs});
  final List<PackEntity> packs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: packs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final pack = packs[i];
          return GestureDetector(
            onTap: () => AppRouter.router.push(
              '${RouteNames.marketplace}/pack/${pack.id}',
            ),
            child: Container(
              width: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navyBlue, AppColors.navyBlueLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  if (pack.coverImageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        pack.coverImageUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        color: Colors.black.withOpacity(0.35),
                        colorBlendMode: BlendMode.darken,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amberOrangeLight.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PROMOTED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pack.titleFor('en'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate(delay: (i * 40).ms).fadeIn().slideX(begin: 0.08, end: 0),
          );
        },
      ),
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
