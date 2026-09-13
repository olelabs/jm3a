import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/avatar/presentation/avatar_creator_screen.dart';
import '../../../../features/packs/domain/pack_entity.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../../shared/widgets/cards/profile_pack_card.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../../../shared/widgets/game/responsive_game_text.dart';
import '../../../../shared/widgets/qr/qr_reveal_sheets.dart';
import '../../../../shared/utils/profile_share.dart';
import '../profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribes to the enclosing PageRoute (HomeShellScreen's — Profile
    // is one of its IndexedStack tabs, not a route of its own), so
    // didPopNext fires whenever any pushed screen (edit profile, avatar
    // editor, theme picker, followers, verification, wallet, settings,
    // pack editor, subscription purchase, ...) is popped back to it.
    // Reuses go_router's own navigator observer instead of every push
    // call site having to remember to await + refresh individually.
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      AppRouter.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<ProfileProvider>().refreshAll();
  }

  Future<void> _onRefresh() => context.read<ProfileProvider>().refreshAll();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final profile = context.watch<ProfileProvider>();
    final theme = context.theme;
    final l10n = context.l10n;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          // Pull-to-refresh needs the scroll view to always be
          // scrollable, even when content is shorter than the viewport
          // (e.g. a brand-new account with no packs yet).
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              actions: [
                // Item 7 (QR codes) — reveal the user's own profile QR,
                // same "username-keyed, never a raw UUID" rule
                // shareProfile already follows (see AppConstants.
                // appProfileLink's own doc comment) — only shown once a
                // username actually exists to encode.
                if ((user.username ?? '').isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.qr_code_rounded),
                    tooltip: l10n.qrProfileRevealTitle,
                    onPressed: () => ProfileQrSheet.show(
                      context,
                      username: user.username!,
                      displayName: user.displayName ?? user.username!,
                      avatarUrl: user.avatarUrl,
                      shareText: l10n.profileShareMessage(
                        user.displayName ?? user.username ?? l10n.packPlayer,
                        AppConstants.publicProfileUrl(user.username!),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: l10n.profileShareAction,
                  onPressed: () => shareProfile(
                    context,
                    user: user,
                    generalScore: profile.stats.generalScore,
                    honestyPoints: profile.stats.honestyPoints,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => AppRouter.router.push(RouteNames.settings),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _ProfileHeader(user: user),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _StatsRow()
                      .animate()
                      .fadeIn(delay: 100.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 20),

                  if (user.bio?.isNotEmpty == true) ...[
                    JCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.profileAbout,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(user.bio!, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ).animate(delay: 150.ms).fadeIn(),
                    const SizedBox(height: 16),
                  ],

                  OutlinedButton.icon(
                    onPressed: () => AppRouter.router.push('/profile/edit'),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l10n.profileEditTitle),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ).animate(delay: 200.ms).fadeIn(),

                  const SizedBox(height: 20),

                  if (profile.mostPlayedPacks.isNotEmpty) ...[
                    _PackSection(
                      title: l10n.profileMostPlayedPacks,
                      packs: profile.mostPlayedPacks,
                    ).animate(delay: 220.ms).fadeIn(),
                    const SizedBox(height: 16),
                  ],

                  if (profile.createdPacks.isNotEmpty) ...[
                    _PackSection(
                      title: l10n.profileMyCreatedPacks,
                      packs: profile.createdPacks,
                    ).animate(delay: 250.ms).fadeIn(),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 4),

                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF5A623), Color(0xFFFF6B35)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          '✦',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      l10n.premiumTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      user.isPremiumActive
                          ? (user.premiumExpiresAt != null
                                ? l10n.profilePremiumActiveExpires(
                                    user.premiumExpiresAt!.day,
                                    user.premiumExpiresAt!.month,
                                    user.premiumExpiresAt!.year,
                                  )
                                : l10n.activeLabel)
                          : l10n.profileUnlockPremiumHint,
                      style: TextStyle(
                        color: user.isPremiumActive
                            ? Colors.green.shade600
                            : null,
                      ),
                    ),
                    trailing: user.isPremiumActive
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Text(
                              l10n.activeLabel,
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () => AppRouter.router.push(RouteNames.premium),
                  ).animate(delay: 260.ms).fadeIn(),

                  if (user.isPremiumActive) ...[
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B68EE).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.palette_outlined,
                          color: Color(0xFF7B68EE),
                          size: 22,
                        ),
                      ),
                      title: Text(
                        l10n.premiumAppThemeTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(l10n.profileChooseColourTheme),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () =>
                          AppRouter.router.push(RouteNames.themePicker),
                    ).animate(delay: 270.ms).fadeIn(),

                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.face_retouching_natural,
                          color: Color(0xFFE91E63),
                          size: 22,
                        ),
                      ),
                      title: Text(
                        l10n.profileMyAvatar,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(l10n.profileCreateAvatarHint),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () =>
                          AppRouter.router.push(RouteNames.avatarCreator),
                    ).animate(delay: 280.ms).fadeIn(),
                  ],

                  if (!user.isVerifiedCreator)
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.verified_outlined,
                          color: Color(0xFF0EA5E9),
                          size: 22,
                        ),
                      ),
                      title: Text(
                        l10n.profileBecomeCreator,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(l10n.profileBecomeCreatorHint),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () =>
                          AppRouter.router.push(RouteNames.creatorVerification),
                    ).animate(delay: 285.ms).fadeIn(),

                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.amberOrangeLight.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.amberOrangeLight,
                        size: 20,
                      ),
                    ),
                    title: Text(l10n.walletTitle),
                    subtitle: Text(l10n.profileBalanceAndTransactions),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () => AppRouter.router.push(RouteNames.wallet),
                  ).animate(delay: 280.ms).fadeIn(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackSection extends StatelessWidget {
  const _PackSection({required this.title, required this.packs});
  final String title;
  final List<PackEntity> packs;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        // Item 2 (this pass) fix — ROOT CAUSE of "the name looks detached
        // from the card": the previous fix put the cover Image and the
        // title Text in a bare Column with no card container around
        // either of them — visually just an image with a caption floating
        // underneath it, not a card. ProfilePackCard (shared with
        // UserProfileScreen's own packs section — see that widget's own
        // doc comment) puts both INSIDE one JCard, cover on top with a
        // subtle Divider marking the boundary before the name section —
        // the "deliberate card section" the name sits in, not a
        // background-behind-text overlay and not a separate widget below
        // the card.
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: packs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final pack = packs[i];
              return ProfilePackCard(
                pack: pack,
                onTap: () => AppRouter.router.push(
                  '${RouteNames.marketplace}/pack/${pack.id}',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    // Item 5 — daily streak. Only shown once a streak actually exists (0
    // means "never started one" — no point showing a cold flame icon).
    // The NUMBER survives a missed day unchanged (on_game_session_completed
    // only ever changes it on the next qualifying completion); the flame
    // itself dims once the streak is no longer live (streakFlameOn), so a
    // stale streak is visually distinguishable without the count itself
    // ever being reset by anything other than an actual new completion.
    final stats = context.watch<ProfileProvider>().stats;
    final currentStreak = stats.currentStreak;
    final streakFlameOn = stats.streakFlameOn;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyBlue, AppColors.navyBlue.withOpacity(0.7)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
          child: Row(
            children: [
              UserAvatar(
                avatarUrl: user.avatarUrl,
                avatarConfig: context.watch<AvatarService>().config.toMap(),
                isPremium: user.isPremiumActive,
                displayName: user.displayName,
                size: 72,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.displayName ?? context.l10n.packPlayer,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (user.username != null)
                      Text(
                        '@${user.username}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    if (currentStreak > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Tooltip(
                          message: streakFlameOn
                              ? context.l10n.profileStreakActive
                              : context.l10n.profileStreakInactive,
                          child: Opacity(
                            opacity: streakFlameOn ? 1.0 : 0.4,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🔥',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  context.l10n.profileStreakDays(currentStreak),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.amberOrangeLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (user.isVerifiedCreator)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: AppColors.amberOrangeLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.l10n.profileVerifiedCreator,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.amberOrangeLight,
                              ),
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
      ),
    );
  }
}

/// Thin data-binding wrapper: reads ProfileProvider + l10n and hands plain
/// values to [ProfileStatsSection]. Kept separate from the section itself
/// so the actual layout is a provider-free, context-l10n-free public
/// widget — directly widget-testable (narrow width, RTL, text scaling,
/// zero/long values) without standing up ProfileProvider/AuthProvider/
/// go_router just to render it.
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = context.watch<ProfileProvider>();
    final loaded = profile.hasLoadedProfileHome;
    final stats = profile.stats;

    return ProfileStatsSection(
      loaded: loaded,
      score: stats.generalScore,
      scoreLabel: l10n.profileScore,
      honestyPoints: stats.honestyPoints,
      honestyLabel: l10n.profileHonestyPoints,
      games: stats.gamesPlayed,
      gamesLabel: l10n.profileGames,
      friends: stats.friendsCount,
      friendsLabel: l10n.profileFriends,
      packs: stats.packsCount,
      packsLabel: l10n.profilePacks,
      followers: stats.followersCount,
      followersLabel: l10n.friendsFollowersTitle,
      onFollowersTap: () => AppRouter.router.push(RouteNames.followers),
    );
  }
}

/// Score (hero, prominent) + Games/Friends/Packs/Followers (lighter, plain
/// Row of four). A plain Row — never a horizontally-scrolling
/// SingleChildScrollView — around Expanded children: that combination is
/// exactly what threw "RenderFlex children have non-zero flex but incoming
/// width constraints are unbounded" (and, from there, a corrupted render
/// tree surfacing as unrelated assertions on other IndexedStack tabs) the
/// last time a 5th box was added here. Expanded children never overflow a
/// plain Row by construction, so four (or five, or any fixed count) never
/// needs a scroll wrapper.
///
/// Public (unlike every other widget in this file) purely so it's directly
/// widget-testable in isolation — it takes plain values/labels, not a
/// provider or BuildContext l10n, so a test can pump it under a bare
/// MaterialApp with no ProfileProvider/AuthProvider/go_router setup.
class ProfileStatsSection extends StatelessWidget {
  const ProfileStatsSection({
    super.key,
    required this.loaded,
    required this.score,
    required this.scoreLabel,
    this.honestyPoints = 0,
    this.honestyLabel = '',
    required this.games,
    required this.gamesLabel,
    required this.friends,
    required this.friendsLabel,
    required this.packs,
    required this.packsLabel,
    required this.followers,
    required this.followersLabel,
    this.onFollowersTap,
  });

  final bool loaded;
  final int score;
  final String scoreLabel;

  /// Distinct reputation ledger from [score] (see honesty_events) — shown
  /// in its own badge below the score hero, NOT as a 5th tile in the
  /// Games/Friends/Packs/Followers Row (see that Row's own doc comment on
  /// why a 5th Expanded box there is unsafe).
  final int honestyPoints;
  final String honestyLabel;
  final int games;
  final String gamesLabel;
  final int friends;
  final String friendsLabel;
  final int packs;
  final String packsLabel;
  final int followers;
  final String followersLabel;
  final VoidCallback? onFollowersTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ScoreHeroCard(score: score, loaded: loaded, label: scoreLabel),
        if (honestyLabel.isNotEmpty) ...[
          const SizedBox(height: 10),
          _HonestyBadge(
            value: honestyPoints,
            loaded: loaded,
            label: honestyLabel,
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            _MiniStatTile(
              icon: Icons.videogame_asset_rounded,
              iconColor: AppColors.brandBlueElectric,
              label: gamesLabel,
              value: loaded ? games : null,
            ),
            const SizedBox(width: 10),
            _MiniStatTile(
              icon: Icons.people_alt_rounded,
              iconColor: AppColors.nhieGreen,
              label: friendsLabel,
              value: loaded ? friends : null,
            ),
            const SizedBox(width: 10),
            _MiniStatTile(
              icon: Icons.inventory_2_rounded,
              iconColor: AppColors.brandPurpleMid,
              label: packsLabel,
              value: loaded ? packs : null,
            ),
            const SizedBox(width: 10),
            _MiniStatTile(
              icon: Icons.favorite_rounded,
              iconColor: AppColors.dareRed,
              label: followersLabel,
              value: loaded ? followers : null,
              onTap: onFollowersTap,
            ),
          ],
        ),
      ],
    );
  }
}

/// The profile's visual hero — General Score is Jma3a's identity/
/// progression metric (item 4), so it gets a full-width, brand-gradient
/// treatment instead of sharing a plain box with the other four stats.
/// Reuses the exact gold→orange gradient already used for the Premium '✦'
/// tile further down this screen (see the ListTile below) rather than
/// inventing a new one — the same warm gradient already reads as "Jma3a
/// achievement/prestige" in this file, and matches the streak flame color
/// (AppColors.amberOrangeLight) in _ProfileHeader above, visually tying
/// score and streak together as the same "progression" family without
/// repeating the streak number itself.
class _ScoreHeroCard extends StatefulWidget {
  const _ScoreHeroCard({
    required this.score,
    required this.loaded,
    required this.label,
  });
  final int score;
  final bool loaded;
  final String label;

  @override
  State<_ScoreHeroCard> createState() => _ScoreHeroCardState();
}

class _ScoreHeroCardState extends State<_ScoreHeroCard>
    with SingleTickerProviderStateMixin {
  // Created eagerly in initState, not as a `late final ... = AnimationController(...)`
  // field initializer — that form only runs on first read, and if the
  // score never actually loads (widget.loaded stays false for this
  // widget's whole lifetime, e.g. a fast test teardown or a profile that
  // never finishes loading before navigating away), _maybeAnimate() never
  // touches _controller, making dispose() its first-ever access — which
  // tries to look up this element's TickerMode ancestor while the element
  // is already deactivated ("Looking up a deactivated widget's ancestor
  // is unsafe"). Eager creation in initState has an active element and
  // never has this problem.
  late final AnimationController _controller;
  Animation<double> _value = const AlwaysStoppedAnimation(0);
  int? _lastAnimatedScore;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeAnimate();
  }

  @override
  void didUpdateWidget(_ScoreHeroCard old) {
    super.didUpdateWidget(old);
    _maybeAnimate();
  }

  // Runs once per genuine score change (first load counts as one) — not a
  // continuously animating widget. Reduced-motion users get the final
  // value immediately; the number is always fully readable either way.
  void _maybeAnimate() {
    if (!widget.loaded || _lastAnimatedScore == widget.score) return;
    final from = (_lastAnimatedScore ?? 0).toDouble();
    _lastAnimatedScore = widget.score;
    _value = Tween<double>(
      begin: from,
      end: widget.score.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5A623), Color(0xFFFF6B35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.elevated(const Color(0xFFFF6B35)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle decorative circles — same low-opacity-white treatment
            // JGameCard already uses, not a new decorative language.
            Positioned(
              top: -26,
              right: -18,
              child: _Circle(size: 100, opacity: 0.08),
            ),
            Positioned(
              bottom: -30,
              left: -24,
              child: _Circle(size: 90, opacity: 0.06),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: _value,
                  builder: (context, _) {
                    final display = widget.loaded
                        ? _groupThousands(_value.value.round())
                        : '—';
                    return ResponsiveGameText(
                      display,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                      minFontSize: 22,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

/// One of the four lighter Games/Friends/Packs/Followers tiles. Deliberately
/// plainer than [_ScoreHeroCard] (flat surface, no gradient) so the score
/// stays the clear visual hero — see item 2's "communicate hierarchy"
/// requirement. `Expanded` is only ever used directly under this tile's
/// parent `Row` (never inside a scrolling container) — see `_StatsRow`.
/// Honesty Points' own distinct treatment — deliberately NOT another
/// `_MiniStatTile` (those are for flat participation counts that are
/// always >= 0; honesty_points is a signed reputation ledger, so it needs
/// a sign-aware color and an explicit +/- prefix a plain tile doesn't
/// have). A slim full-width strip rather than a second hero card keeps
/// the score the unambiguous visual focus, per _ScoreHeroCard's own doc
/// comment on hierarchy.
class _HonestyBadge extends StatelessWidget {
  const _HonestyBadge({
    required this.value,
    required this.loaded,
    required this.label,
  });

  final int value;
  final bool loaded;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isNegative = value < 0;
    final isZero = value == 0;
    final color = !loaded
        ? context.colorScheme.onSurfaceVariant
        : isNegative
        ? AppColors.dareRed
        : isZero
        ? context.colorScheme.onSurfaceVariant
        : AppColors.nhieGreen;
    final display = loaded
        ? '${value > 0 ? '+' : ''}${_groupThousands(value)}'
        : '—';
    return JCard(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.handshake_rounded, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            display,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatTile extends StatelessWidget {
  const _MiniStatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final int? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: JCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            const SizedBox(height: 6),
            ResponsiveGameText(
              value != null ? _groupThousands(value!) : '—',
              style:
                  context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ) ??
                  const TextStyle(fontWeight: FontWeight.w700),
              minFontSize: 11,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Locale-neutral thousands grouping ("12450" -> "12,450") — deliberately
/// not `NumberFormat` here: the score is a brand identity number shown at
/// a large display size, and should read identically (Western digits,
/// comma grouping) in every supported language rather than switching to
/// Eastern Arabic numerals under the 'ar' locale the way a fully
/// locale-aware formatter would.
String _groupThousands(int n) {
  final negative = n < 0;
  final digits = n.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return negative ? '-$buffer' : buffer.toString();
}
