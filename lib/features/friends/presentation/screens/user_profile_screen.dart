import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/presence_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../../../../shared/widgets/media/signed_network_image.dart';
import '../../../packs/data/pack_repository.dart';
import '../../../packs/domain/pack_entity.dart';
import '../../presentation/friends_provider.dart';
import '../widgets/online_indicator.dart';

/// Correction-pass §12 — the shared official-account action policy. Every
/// surface that offers a friend-request/block/invite-to-room action on a
/// target profile MUST route its visibility decision through one of these
/// three functions rather than repeating `if (profile.isOfficial)` ad hoc
/// — this file's own official-profile branch, room member menus, and
/// explore/search results all use the same three checks. Follow is never
/// gated by any of these — anyone can follow/unfollow the official
/// account like any other profile.
///
/// None of these are the real authority on their own — a tampered client
/// could still call the underlying insert directly, which is exactly what
/// the matching RLS policy rejects regardless of what this function
/// returns (see 20260901090700_block_official_account_friend_requests.sql
/// for friend requests, and 20260901094300_official_account_action_
/// restrictions.sql for block/room-invite). UI-level suppression exists
/// so a user is never shown a control that would fail, not as the
/// security boundary itself.
bool canShowFriendRequestAction(SocialProfile profile) =>
    !profile.isOfficial && profile.canInteract;

/// Whether a Block action should ever be offered for [profile]. Jma3a
/// Official can never be blocked — see 20260901094300_official_account_
/// action_restrictions.sql's blocked_users INSERT policy extension.
bool canShowBlockAction(SocialProfile profile) => !profile.isOfficial;

/// Whether an "Invite to room" action should ever be offered for
/// [profile]. Jma3a Official can never be invited to a room — see
/// 20260901094300_official_account_action_restrictions.sql's
/// room_invites INSERT policy extension.
bool canShowInviteToRoomAction(SocialProfile profile) => !profile.isOfficial;

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  SocialProfile? _profile;
  List<PackEntity> _packs = [];
  List<PackEntity> _mostPlayed = [];
  bool _isLoading = true;
  bool _isActing = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        context.read<FriendsProvider>().getSocialProfile(widget.userId),
        sl.packRepository.getPublicPacksByCreator(widget.userId),
        sl.packRepository.getMostPlayedPacksForUser(widget.userId),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as SocialProfile;
          _packs = results[1] as List<PackEntity>;
          _mostPlayed = results[2] as List<PackEntity>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e;
          _isLoading = false;
        });
    }
  }

  Future<void> _act(Future<void> Function() fn) async {
    setState(() => _isActing = true);
    await fn();
    await _load();
    setState(() => _isActing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null || _profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: context.l10n.friendsProfileNotFound,
          onRetry: _load,
        ),
      );
    }

    final p = _profile!;
    final friends = context.watch<FriendsProvider>();
    final theme = context.theme;

    // Official Jma3a system creator profile: a completely different,
    // minimal screen — no edit/follow/friend actions, no stats beyond
    // packs, always verified. See profiles.is_official_account and
    // SocialProfile.isOfficial for why this is a real flag, not a
    // displayName == 'Jma3a' string check.
    if (p.isOfficial) {
      return Scaffold(
        appBar: AppBar(title: Text(p.displayName)),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OfficialProfileHeader(p: p).animate().fadeIn(),
              // Official can be followed like anyone else — only friend
              // requests are disallowed for this account (server-enforced,
              // see 20260901090700_block_official_account_friend_requests.sql).
              // No _FriendshipAction here — that's the one action that must
              // never be offered for the official profile.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _isActing
                    ? const Center(child: CircularProgressIndicator())
                    : _FollowAction(profile: p, friends: friends, onAct: _act),
              ),
              if (_packs.isNotEmpty) ...[
                _SectionHeader(
                  title: context.l10n.friendsCreatedBy(p.displayName),
                  emoji: '🎴',
                ),
                // §9 — a grid, not the normal profile's horizontal
                // scroller: the official identity is defined largely by
                // its catalog, so it gets the more prominent presentation.
                // shrinkWrap + NeverScrollable since this whole screen is
                // already one SingleChildScrollView.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _packs.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemBuilder: (_, i) =>
                        _OfficialPackGridTile(
                              pack: _packs[i],
                              onTap: () => context.push(
                                '${RouteNames.marketplace}/pack/${_packs[i].id}',
                              ),
                            )
                            .animate(delay: (i * 40).ms)
                            .fadeIn(),
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      context.l10n.packNoPacksYet,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(p.displayName),
        actions: [
          if (!p.isBlocked && !p.isBlockedBy)
            PopupMenuButton<String>(
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block_rounded, color: AppColors.errorRed),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.friendsBlock,
                        style: TextStyle(color: AppColors.errorRed),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (v) {
                if (v == 'block') _act(() => friends.blockUser(p.userId));
              },
            ),
        ],
      ),
      body: _isActing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(
                    p: p,
                  ).animate().fadeIn().slideY(begin: -0.05, end: 0),
                  _StatsRow(p: p).animate(delay: 80.ms).fadeIn(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Align(
                      alignment: Alignment.center,
                      child: _HonestyStatBadge(value: p.honestyPoints),
                    ),
                  ).animate(delay: 100.ms).fadeIn(),
                  if (p.isBlocked || p.isBlockedBy) _BlockedBanner(p: p),
                  if (p.canInteract)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Column(
                        children: [
                          if (canShowFriendRequestAction(p)) ...[
                            _FriendshipAction(
                              profile: p,
                              friends: friends,
                              onAct: _act,
                            ),
                            const SizedBox(height: 10),
                          ],
                          _FollowAction(
                            profile: p,
                            friends: friends,
                            onAct: _act,
                          ),
                          if (p.isBlocked) ...[
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () =>
                                  _act(() => friends.unblockUser(p.userId)),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 44),
                              ),
                              child: Text(context.l10n.friendsUnblock),
                            ),
                          ],
                        ],
                      ).animate(delay: 120.ms).fadeIn(),
                    ),
                  if (!p.isBlocked &&
                      !p.isBlockedBy &&
                      _mostPlayed.isNotEmpty) ...[
                    _SectionHeader(
                      title: context.l10n.friendsMostPlayedBy(p.displayName),
                      emoji: '🔥',
                    ),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _mostPlayed.length,
                        itemBuilder: (_, i) =>
                            _PackCard(
                                  pack: _mostPlayed[i],
                                  onTap: () => context.push(
                                    '${RouteNames.marketplace}/pack/${_mostPlayed[i].id}',
                                  ),
                                )
                                .animate(delay: (i * 40).ms)
                                .fadeIn()
                                .slideX(begin: 0.1, end: 0),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (!p.isBlocked && !p.isBlockedBy && _packs.isNotEmpty) ...[
                    _SectionHeader(
                      title: context.l10n.friendsCreatedBy(p.displayName),
                      emoji: '🎴',
                    ),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _packs.length,
                        itemBuilder: (_, i) =>
                            _PackCard(
                                  pack: _packs[i],
                                  onTap: () => context.push(
                                    '${RouteNames.marketplace}/pack/${_packs[i].id}',
                                  ),
                                )
                                .animate(delay: (i * 40).ms)
                                .fadeIn()
                                .slideX(begin: 0.1, end: 0),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (!p.isBlocked &&
                      !p.isBlockedBy &&
                      _packs.isEmpty &&
                      _mostPlayed.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          context.l10n.packNoPacksYet,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.p});
  final SocialProfile p;
  @override
  Widget build(BuildContext context) {
    // FriendsProvider.isOnline()/statusOf() only track this user's own
    // friend list — fine for the Friends screen, but this screen opens
    // for ANY user (pack creators, room members, search results), who
    // are frequently not a friend at all. PresenceService's presence
    // channel already covers every authenticated user, not just friends,
    // so read it directly here instead — same realtime source, no new
    // presence system, just the right scope of consumer for a non-friend
    // viewer. StreamBuilder (not a one-off read) keeps this live for as
    // long as the screen is open, matching "online indicator disappears
    // immediately" when the viewed user goes offline.
    // Detail (lobby vs. specific game) is a premium feature, gated on
    // the *viewer's* own premium status — same rule as the Friends
    // screen list.
    final showDetail =
        context.watch<AuthProvider>().currentUser?.isPremiumActive ?? false;

    return StreamBuilder<Map<String, UserPresence>>(
      stream: PresenceService.instance.presenceStream,
      initialData: PresenceService.instance.currentPresence,
      builder: (context, snapshot) {
        final presence = snapshot.data?[p.userId];
        return _ProfileHeaderContent(
          p: p,
          status: presence?.status ?? UserPresenceStatus.offline,
          roomStatus: presence?.roomStatus,
          gameType: presence?.gameType,
          showDetail: showDetail,
        );
      },
    );
  }
}

class _ProfileHeaderContent extends StatelessWidget {
  const _ProfileHeaderContent({
    required this.p,
    required this.status,
    this.roomStatus,
    this.gameType,
    this.showDetail = false,
  });
  final SocialProfile p;
  final String? roomStatus;
  final String? gameType;
  final bool showDetail;
  final UserPresenceStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          UserAvatar(
            avatarUrl: p.avatarUrl,
            avatarConfig: p.avatarConfig,
            isPremium: p.isPremium,
            displayName: p.displayName,
            size: 80,
            showOnlineStatus: !p.isBlockedBy && !p.isBlocked,
            isOnline: status != UserPresenceStatus.offline,
          ).animate().scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: 300.ms,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                p.displayName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (p.isPremium) ...[
                const SizedBox(width: 6),
                const Text(
                  '✦',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFF5A623),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
              if (p.isVerified) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.verified_rounded,
                  size: 20,
                  color: AppColors.infoBlue,
                ),
              ],
            ],
          ),
          if (p.username != null)
            Text(
              '@${p.username}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (p.currentStreak > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  context.l10n.profileStreakDays(p.currentStreak),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.amberOrangeLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          if (p.bio != null && p.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              p.bio!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          if (!p.isBlockedBy && !p.isBlocked) ...[
            const SizedBox(height: 8),
            OnlineIndicator(
              status: status,
              showLabel: true,
              roomStatus: roomStatus,
              gameType: gameType,
              showDetail: showDetail,
            ),
          ],
        ],
      ),
    );
  }
}

class _OfficialProfileHeader extends StatelessWidget {
  const _OfficialProfileHeader({required this.p});
  final SocialProfile p;

  // Correction-pass §10 — the official profile's cover/background. There
  // is no `profiles` column for this (checked live: `profiles` has no
  // cover/background/banner column at all, official or otherwise) and
  // this is a single fixed brand row, not per-user content — a bundled
  // asset is the right call, not a new schema column + storage upload
  // pipeline for one row. Reuses the SAME asset already bundled for
  // in-game card backgrounds' own default-cover fallback
  // (jma3a_card_background.png, distinct from jma3a_card_cover_playful.png
  // which GameCardBackground uses — this one is literally named for the
  // "background" use case), rather than introducing a third brand image.
  static const _coverAsset = 'assets/images/backgrounds/jma3a_card_background.png';

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: Image.asset(_coverAsset, fit: BoxFit.cover),
              ),
              Positioned(
                bottom: -40,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: const UserAvatar(size: 80, isOfficial: true).animate().scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: 300.ms,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                p.displayName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.verified_rounded,
                size: 20,
                color: AppColors.infoBlue,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.friendsOfficialAccount,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          // §5 — the ONLY count an official profile shows: followers.
          // Never friendsCount/gamesPlayed/generalScore/honestyPoints —
          // this branch never reaches _StatsRow/_HonestyStatBadge at all.
          Text(
            context.l10n.friendsFollowersCount(p.followersCount),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.p});
  final SocialProfile p;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          _StatCell(
            label: context.l10n.profileFriends,
            value: '${p.friendsCount}',
          ),
          _Divider(),
          _StatCell(
            label: context.l10n.profileFollowers,
            value: '${p.followersCount}',
          ),
          _Divider(),
          _StatCell(
            label: context.l10n.profileGames,
            value: '${p.gamesPlayed}',
          ),
          _Divider(),
          _StatCell(label: context.l10n.profilePacks, value: '${p.packsCount}'),
          _Divider(),
          _StatCell(
            label: context.l10n.profileScore,
            value: '${p.generalScore}',
          ),
        ],
      ),
    );
  }
}

class _BlockedBanner extends StatelessWidget {
  const _BlockedBanner({required this.p});
  final SocialProfile p;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.block_rounded, color: AppColors.errorRed),
          const SizedBox(width: 10),
          Text(
            p.isBlocked
                ? context.l10n.friendsYouHaveBlocked
                : context.l10n.friendsCannotInteract,
            style: const TextStyle(color: AppColors.errorRed),
          ),
        ],
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.emoji});
  final String title, emoji;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          title,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _PackCard extends StatelessWidget {
  const _PackCard({required this.pack, required this.onTap});
  final PackEntity pack;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: pack.coverImageUrl != null
                  ? SignedNetworkImage(
                      url: pack.coverImageUrl!,
                      height: 80,
                      width: 130,
                      fit: BoxFit.cover,
                      errorBuilder: (_) => _PackCoverPlaceholder(pack: pack),
                    )
                  : _PackCoverPlaceholder(pack: pack),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pack.titleFor(Localizations.localeOf(context).languageCode),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Color(0xFFF5A623),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${pack.avgRating.toStringAsFixed(1)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${pack.totalPlays} 🎮',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                        ),
                      ),
                    ],
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

/// §9 — grid tile for the official profile's pack catalog. Same cover/
/// placeholder resolution as [_PackCard] (SignedNetworkImage when the
/// pack has its own cover, else an emoji placeholder matching the
/// game type — same convention this screen already established, kept
/// consistent rather than reaching for a different fallback widget from
/// elsewhere in the app), just sized to fill its GridView cell instead of
/// a fixed 130px horizontal-scroller card.
class _OfficialPackGridTile extends StatelessWidget {
  const _OfficialPackGridTile({required this.pack, required this.onTap});
  final PackEntity pack;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: pack.coverImageUrl != null
                  ? SignedNetworkImage(
                      url: pack.coverImageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_) => _GridCoverPlaceholder(pack: pack),
                    )
                  : _GridCoverPlaceholder(pack: pack),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                pack.titleFor(Localizations.localeOf(context).languageCode),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridCoverPlaceholder extends StatelessWidget {
  const _GridCoverPlaceholder({required this.pack});
  final PackEntity pack;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Center(
      child: Text(
        pack.gameType == 'truth_or_dare'
            ? '🎯'
            : pack.gameType == 'never_have_i_ever'
            ? '🍹'
            : '😂',
        style: const TextStyle(fontSize: 32),
      ),
    ),
  );
}

class _PackCoverPlaceholder extends StatelessWidget {
  const _PackCoverPlaceholder({required this.pack});
  final PackEntity pack;
  @override
  Widget build(BuildContext context) => Container(
    height: 80,
    width: 130,
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Center(
      child: Text(
        pack.gameType == 'truth_or_dare'
            ? '🎯'
            : pack.gameType == 'never_have_i_ever'
            ? '🍹'
            : '😂',
        style: const TextStyle(fontSize: 32),
      ),
    ),
  );
}

/// Honesty Points get a distinct pill treatment, not another _StatCell —
/// it's a signed reputation ledger (can go negative), not a flat
/// participation count, so it needs its own sign-aware color/prefix.
class _HonestyStatBadge extends StatelessWidget {
  const _HonestyStatBadge({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    final isNegative = value < 0;
    final isZero = value == 0;
    final color = isNegative
        ? AppColors.errorRed
        : isZero
            ? context.colorScheme.onSurfaceVariant
            : AppColors.nhieGreen;
    final display = '${value > 0 ? '+' : ''}$value';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.handshake_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '${context.l10n.profileHonestyPoints}: $display',
            style: context.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 32,
    color: context.colorScheme.outlineVariant,
  );
}

class _FriendshipAction extends StatelessWidget {
  const _FriendshipAction({
    required this.profile,
    required this.friends,
    required this.onAct,
  });
  final SocialProfile profile;
  final FriendsProvider friends;
  final Future<void> Function(Future<void> Function()) onAct;
  @override
  Widget build(BuildContext context) {
    final status = profile.friendshipStatus;
    final isSentRequest = friends.sentRequests.any(
      (r) => r.userId == profile.userId,
    );
    if (status == FriendshipStatus.accepted) {
      return OutlinedButton.icon(
        onPressed: () => onAct(() => friends.removeFriend(profile.userId)),
        icon: const Icon(Icons.person_remove_outlined),
        label: Text(context.l10n.friendsRemoveFriend),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
        ),
      );
    }
    if (status == FriendshipStatus.pending) {
      // profile.isFriendshipRequester (a live per-pair lookup) is the
      // authoritative signal for who actually sent this request;
      // isSentRequest (FriendsProvider's cached sentRequests list) is
      // only consulted as an immediate-feedback fallback right after
      // sending, before this profile has been re-fetched.
      final iSentIt = profile.isFriendshipRequester || isSentRequest;
      if (!iSentIt) {
        // They sent it to me — offer Accept/Reject, not Cancel.
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () =>
                    onAct(() => friends.acceptRequest(profile.userId)),
                icon: const Icon(Icons.check_rounded),
                label: Text(context.l10n.friendsAccept),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    onAct(() => friends.rejectRequest(profile.userId)),
                icon: const Icon(Icons.close_rounded),
                label: Text(context.l10n.friendsReject),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ),
          ],
        );
      }
      return OutlinedButton.icon(
        onPressed: () => onAct(() => friends.cancelRequest(profile.userId)),
        icon: const Icon(Icons.cancel_outlined),
        label: Text(context.l10n.friendsCancelRequest),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
        ),
      );
    }
    return JButton(
      label: context.l10n.friendsAddFriend,
      onPressed: () =>
          onAct(() => friends.sendFriendRequest(profile.userId).then((_) {})),
      icon: Icons.person_add_outlined,
    );
  }
}

class _FollowAction extends StatelessWidget {
  const _FollowAction({
    required this.profile,
    required this.friends,
    required this.onAct,
  });
  final SocialProfile profile;
  final FriendsProvider friends;
  final Future<void> Function(Future<void> Function()) onAct;
  @override
  Widget build(BuildContext context) {
    if (profile.isFollowing) {
      return OutlinedButton.icon(
        onPressed: () =>
            onAct(() => friends.unfollowUser(profile.userId).then((_) {})),
        icon: const Icon(Icons.remove_circle_outline_rounded),
        label: Text(context.l10n.friendsUnfollow),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
        ),
      );
    }
    return FilledButton.tonal(
      onPressed: () =>
          onAct(() => friends.followUser(profile.userId).then((_) {})),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 44),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_rounded),
          const SizedBox(width: 6),
          Text(context.l10n.friendsFollow),
        ],
      ),
    );
  }
}
