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
import '../../../../features/profile/presentation/screens/profile_screen.dart'
    show ProfileStatsSection;
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../../shared/widgets/cards/profile_pack_card.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../../../../shared/widgets/media/signed_network_image.dart';
import '../../../packs/data/pack_repository.dart';
import '../../../packs/domain/pack_entity.dart';
import '../../presentation/friends_provider.dart';
import '../widgets/online_indicator.dart';
import '../widgets/report_user_sheet.dart';

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

/// Item 9 fix ("tap a follower -> Profile not found") — whether at least
/// one piece of known public identity was passed through from the list row
/// that led to this screen, i.e. whether [buildKnownIdentityFallbackProfile]
/// has anything real to build from. Pure so it's directly unit-testable.
bool hasKnownIdentity({String? knownDisplayName, String? knownUsername}) =>
    (knownDisplayName != null && knownDisplayName.isNotEmpty) ||
    (knownUsername != null && knownUsername.isNotEmpty);

/// Builds the minimal fallback [SocialProfile] used when
/// FriendsProvider.getSocialProfile fails but the caller already knows this
/// person's basic public identity from the list row that led here (see
/// _UserProfileScreenState._load's own doc comment for the exact failure
/// this protects against). Pure — no network/BuildContext — so it's
/// directly unit-testable without a live database. Stats/friendship/block
/// state are unknown here, so they default to zero/false; canInteract
/// stays true (not blocked by default) so Follow still works.
SocialProfile buildKnownIdentityFallbackProfile({
  required String userId,
  String? knownDisplayName,
  String? knownUsername,
  String? knownAvatarUrl,
  Map<String, dynamic>? knownAvatarConfig,
  bool knownIsPremium = false,
}) => SocialProfile(
  userId: userId,
  displayName: knownDisplayName?.isNotEmpty == true
      ? knownDisplayName!
      : (knownUsername ?? userId),
  username: knownUsername,
  avatarUrl: knownAvatarUrl,
  avatarConfig: knownAvatarConfig,
  isPremium: knownIsPremium,
  followersCount: 0,
  followingCount: 0,
  friendsCount: 0,
);

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
    required this.userId,
    this.knownDisplayName,
    this.knownUsername,
    this.knownAvatarUrl,
    this.knownAvatarConfig,
    this.knownIsPremium = false,
  });
  final String userId;

  /// Item 9 fix — "tap a follower -> Profile not found": every list this
  /// screen is opened from (Followers, Explore, Friends) already has the
  /// target's basic public identity in hand (it's what rendered their row)
  /// BEFORE this screen ever calls getSocialProfile. Passing it through
  /// means a full profile-lookup failure degrades to a minimal-but-real
  /// profile view instead of a dead-end "not found" error — see [_load]'s
  /// own comment for exactly which failure this protects against. None of
  /// these are trusted as-is for anything privacy-sensitive (stats,
  /// friendship/block state) — only for the same publicly-visible fields
  /// already shown in the list row that led here.
  final String? knownDisplayName;
  final String? knownUsername;
  final String? knownAvatarUrl;
  final Map<String, dynamic>? knownAvatarConfig;
  final bool knownIsPremium;

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
    // getSocialProfile is awaited separately from the pack queries (not
    // inside the same Future.wait as before) so a genuine profile-lookup
    // failure can be told apart from a packs-query failure — the previous
    // single catch-all attributed EITHER failure to the same generic
    // "Profile not found" message, which made this bug impossible to
    // diagnose from the symptom alone. The actual underlying exception is
    // still logged by FriendsRepository's own guardedCall either way.
    SocialProfile? profile;
    Object? profileError;
    try {
      profile = await context.read<FriendsProvider>().getSocialProfile(
        widget.userId,
      );
    } catch (e) {
      profileError = e;
    }

    // ROOT CAUSE this branch guards against: getSocialProfile queries
    // profiles_public first, falling back to the base `profiles` table
    // only if that view has nothing for this id. That fallback is subject
    // to the SAME row-level security a normal client already has on
    // `profiles` for a non-self target — if profiles_public genuinely
    // excludes this row (a real, verified reason this repo cannot inspect
    // without a live database, but privacy/incomplete-profile view
    // filtering is the standard pattern for exactly this kind of view+
    // locked-base-table split) the fallback can legitimately return
    // nothing or be denied, and the ONLY signal that reaches this screen
    // is "not found" — even though the follower/friend/explore row that
    // led here proves this account is real and was already safely shown
    // once. Rather than dead-ending on an error for a relationship the
    // user can clearly see exists, fall back to the same publicly-visible
    // identity fields already rendered in that list row (see
    // buildKnownIdentityFallbackProfile's own doc comment).
    if (profile == null &&
        hasKnownIdentity(
          knownDisplayName: widget.knownDisplayName,
          knownUsername: widget.knownUsername,
        )) {
      profile = buildKnownIdentityFallbackProfile(
        userId: widget.userId,
        knownDisplayName: widget.knownDisplayName,
        knownUsername: widget.knownUsername,
        knownAvatarUrl: widget.knownAvatarUrl,
        knownAvatarConfig: widget.knownAvatarConfig,
        knownIsPremium: widget.knownIsPremium,
      );
    }

    if (profile == null) {
      if (mounted) {
        setState(() {
          _error = profileError ?? Exception('Profile not found');
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final results = await Future.wait([
        sl.packRepository.getPublicPacksByCreator(widget.userId),
        sl.packRepository.getMostPlayedPacksForUser(widget.userId),
      ]);
      if (mounted) {
        setState(() {
          _profile = profile;
          _packs = results[0];
          _mostPlayed = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      // Packs failed but the profile itself is real and known — still show
      // it (with empty pack sections) rather than erroring the whole
      // screen over a secondary query.
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _act(Future<void> Function() fn) async {
    setState(() => _isActing = true);
    await fn();
    await _load();
    setState(() => _isActing = false);
  }

  /// Item 9 — Report / Report & Block. Reuses [ReportUserSheet]
  /// (mirroring ReportPackSheet's own flow) and FriendsProvider.reportUser
  /// (backed by the generic `reports` table's anti-duplicate constraint —
  /// no separate logic here). [alsoBlock] additionally calls the EXISTING
  /// blockUser after a successful report, rather than a second/duplicated
  /// blocking implementation.
  Future<void> _showReportSheet(String targetUserId, {required bool alsoBlock}) async {
    final friends = context.read<FriendsProvider>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportUserSheet(
        targetUserId: targetUserId,
        onSubmit: (reason, details) async {
          final ok = await friends.reportUser(
            targetUserId: targetUserId,
            reason: reason,
            details: details,
          );
          if (ok) {
            if (alsoBlock) {
              await _act(() => friends.blockUser(targetUserId));
            } else if (mounted) {
              context.showSnackBar(context.l10n.packReportSubmitted);
            }
          }
          return ok;
        },
      ),
    );
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                    itemBuilder: (_, i) => _OfficialPackGridTile(
                      pack: _packs[i],
                      onTap: () => context.push(
                        '${RouteNames.marketplace}/pack/${_packs[i].id}',
                      ),
                    ).animate(delay: (i * 40).ms).fadeIn(),
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

    // Item 9 — own profile must never offer Report/Block against yourself.
    // isOfficial already fully short-circuits into a separate, actions-free
    // Scaffold above (see the early return a few lines up), so this menu
    // is never reached for the official account at all.
    final isSelf = p.userId == friends.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.displayName),
        actions: [
          if (!p.isBlocked && !p.isBlockedBy && !isSelf)
            PopupMenuButton<String>(
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, color: AppColors.errorRed),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.friendsReport,
                        style: TextStyle(color: AppColors.errorRed),
                      ),
                    ],
                  ),
                ),
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
                PopupMenuItem(
                  value: 'report_block',
                  child: Row(
                    children: [
                      Icon(
                        Icons.report_gmailerrorred_rounded,
                        color: AppColors.errorRed,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.friendsReportAndBlock,
                        style: TextStyle(color: AppColors.errorRed),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (v) {
                switch (v) {
                  case 'block':
                    _act(() => friends.blockUser(p.userId));
                  case 'report':
                    _showReportSheet(p.userId, alsoBlock: false);
                  case 'report_block':
                    _showReportSheet(p.userId, alsoBlock: true);
                }
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
                  // Item 3 (this pass) — reuses the SAME polished stats
                  // card language ProfileScreen's own profile already
                  // uses (score hero + honesty pill + games/friends/packs/
                  // followers mini-tiles) instead of a separate, plainer
                  // Row-of-numbers implementation, so "my profile" and
                  // "their profile" read as the same product. Followers
                  // has no onTap here — there is no "view someone else's
                  // followers list" screen yet (FollowersScreen is
                  // hardcoded to the signed-in user's own followers), so
                  // this tile is informational only rather than inventing
                  // that feature.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: ProfileStatsSection(
                      loaded: true,
                      score: p.generalScore,
                      scoreLabel: context.l10n.profileScore,
                      honestyPoints: p.honestyPoints,
                      honestyLabel: context.l10n.profileHonestyPoints,
                      games: p.gamesPlayed,
                      gamesLabel: context.l10n.profileGames,
                      friends: p.friendsCount,
                      friendsLabel: context.l10n.profileFriends,
                      packs: p.packsCount,
                      packsLabel: context.l10n.profilePacks,
                      followers: p.followersCount,
                      followersLabel: context.l10n.profileFollowers,
                    ),
                  ).animate(delay: 80.ms).fadeIn(),
                  if (p.isBlocked || p.isBlockedBy) _BlockedBanner(p: p),
                  if (p.canInteract)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                      height: 156,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _mostPlayed.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, i) =>
                            ProfilePackCard(
                                  pack: _mostPlayed[i],
                                  showStats: true,
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
                      height: 156,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _packs.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, i) =>
                            ProfilePackCard(
                                  pack: _packs[i],
                                  showStats: true,
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
    // Item 3 (this pass) — "polished profile background" instead of a flat
    // single-color Container: a soft gradient from the ACTIVE theme's own
    // primary color (colorScheme.primary already reflects whatever app
    // theme/background color the VIEWER has selected — see JCard's own
    // doc comment on why reading it here, rather than a hardcoded color,
    // is what makes this automatically follow the user's theme) down into
    // the ordinary surface color, so every profile immediately reads as a
    // real "header" section instead of a plain settings-page block.
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.22),
            theme.colorScheme.surface,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: UserAvatar(
              avatarUrl: p.avatarUrl,
              avatarConfig: p.avatarConfig,
              isPremium: p.isPremium,
              displayName: p.displayName,
              size: 88,
              showOnlineStatus: !p.isBlockedBy && !p.isBlocked,
              isOnline: status != UserPresenceStatus.offline,
            ),
          ).animate().scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: 300.ms,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  p.displayName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          if (p.username != null) ...[
            const SizedBox(height: 2),
            Text(
              '@${p.username}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (!p.isBlockedBy && !p.isBlocked) ...[
            const SizedBox(height: 10),
            OnlineIndicator(
              status: status,
              showLabel: true,
              roomStatus: roomStatus,
              gameType: gameType,
              showDetail: showDetail,
            ),
          ],
          if (p.currentStreak > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.amberOrangeLight.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 13)),
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
            ),
          ],
          if (p.bio != null && p.bio!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              p.bio!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
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
  static const _coverAsset =
      'assets/images/backgrounds/jma3a_card_background.png';

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
                  child: const UserAvatar(size: 80, isOfficial: true)
                      .animate()
                      .scale(
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
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

/// §9 — grid tile for the official profile's pack catalog. Same cover/
/// placeholder resolution as ProfilePackCard (the shared, non-official
/// pack card this screen's normal-user branch now uses — see
/// shared/widgets/cards/profile_pack_card.dart): SignedNetworkImage when
/// the pack has its own cover, else an emoji placeholder matching the
/// game type — same convention this screen already established, kept
/// consistent rather than reaching for a different fallback widget from
/// elsewhere in the app), just sized to fill its GridView cell instead of
/// a fixed-width horizontal-scroller card. Deliberately NOT unified with
/// ProfilePackCard: the official catalog is a grid (fills its cell), not
/// a fixed-width horizontal strip, and per item 1 of this pass the
/// official profile is intentionally being left alone, not redesigned.
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
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
