import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../friends_provider.dart';
import 'user_profile_screen.dart';

/// Item 4 (this pass) — a follow-back-status lookup failure must never
/// discard an already-successfully-fetched followers list. Before this,
/// [_FollowersScreenState._load] wrapped both [FriendsRepository.
/// getFollowers] and [FriendsRepository.getFollowStatuses] in the SAME
/// try/catch, so if the second (purely cosmetic "are you already
/// following them back") call failed for any reason — a transient
/// network blip, for instance — the whole screen fell into the error
/// state and the followers list that had already loaded correctly was
/// thrown away. This is exactly the "I have followers but the screen
/// shows nothing" symptom, with a real, verifiable cause independent of
/// any server-side RLS policy. A top-level pure function (not inlined in
/// the widget) so the fallback shape is independently unit-testable.
Map<String, bool> defaultFollowStatuses(List<FollowEntity> followers) => {
  for (final f in followers) f.userId: false,
};

/// The current user's own followers list — reuses FriendsRepository/
/// FriendsProvider's existing follow methods (followUser/unfollowUser)
/// rather than a parallel follow system, plus the new bulk
/// getFollowStatuses helper so each row's Follow/Following state is
/// correct without an N+1 query.
class FollowersScreen extends StatefulWidget {
  const FollowersScreen({super.key});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  List<FollowEntity> _followers = [];
  Map<String, bool> _followingBack = {};
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    var userId = auth.currentUser?.id;
    if (userId == null) {
      // AuthProvider can still be mid-hydration on the very first
      // navigation into this screen right after launch/login (its
      // isInitializing flag flips false once the session finishes
      // loading). The old code silently returned here with `_loading`
      // still true from the field initializer — an infinite spinner with
      // no error and no retry, which looked like "sometimes empty" and
      // depended on whatever earlier navigation happened to have already
      // finished hydrating auth by the time this screen was reopened.
      // Wait for that hydration once instead of giving up immediately.
      if (auth.isInitializing) {
        await _waitForAuthReady(auth);
      }
      userId = auth.currentUser?.id;
    }
    if (userId == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final repo = FriendsRepository.instance;
      final followers = await repo.getFollowers(userId, limit: 200);
      Map<String, bool> statuses;
      try {
        statuses = await repo.getFollowStatuses(
          viewerId: userId,
          otherIds: followers.map((f) => f.userId).toList(),
        );
      } catch (e) {
        // Item 4 (this pass) — getFollowers already succeeded above; a
        // failure here is only the secondary "are you already following
        // them back" lookup, not the followers list itself. Degrade to
        // "not following back" for every row (the same as a brand-new
        // viewer with no follows of their own) rather than discarding a
        // followers list that already loaded correctly — see
        // defaultFollowStatuses' doc comment for the full reasoning.
        AppLogger.warning('FollowersScreen: getFollowStatuses failed: $e');
        statuses = defaultFollowStatuses(followers);
      }
      if (mounted) {
        setState(() {
          _followers = followers;
          _followingBack = statuses;
        });
      }
    } catch (_) {
      // A failure here previously left `_followers` at its initial empty
      // list with no signal — indistinguishable from a genuinely empty
      // followers list. Surface it instead so a real error is never
      // silently mistaken for "no followers yet".
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _waitForAuthReady(AuthProvider auth) {
    if (!auth.isInitializing) return Future.value();
    final completer = Completer<void>();
    void listener() {
      if (!auth.isInitializing) {
        auth.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      }
    }

    auth.addListener(listener);
    return completer.future;
  }

  Future<void> _followBack(String targetUserId) async {
    final ok = await context.read<FriendsProvider>().followUser(targetUserId);
    if (ok && mounted) {
      setState(() => _followingBack = {..._followingBack, targetUserId: true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.friendsFollowersTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? ErrorView(message: context.l10n.errorUnexpected, onRetry: _load)
          : _followers.isEmpty
          ? Center(child: Text(context.l10n.friendsNoFollowersYet))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _followers.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (context, i) {
                  final f = _followers[i];
                  final amFollowing = _followingBack[f.userId] ?? false;
                  return ListTile(
                    leading: UserAvatar(
                      avatarUrl: f.avatarUrl,
                      avatarConfig: f.avatarConfig,
                      isPremium: f.isPremium,
                      displayName: f.displayName,
                      size: 44,
                    ),
                    title: Text(f.displayName),
                    subtitle: f.username != null
                        ? Text('@${f.username}')
                        : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: context.read<FriendsProvider>(),
                          child: UserProfileScreen(
                            userId: f.userId,
                            knownDisplayName: f.displayName,
                            knownUsername: f.username,
                            knownAvatarUrl: f.avatarUrl,
                            knownAvatarConfig: f.avatarConfig,
                            knownIsPremium: f.isPremium,
                          ),
                        ),
                      ),
                    ),
                    // The app-wide FilledButtonThemeData sets
                    // minimumSize: Size(double.infinity, 52) (for full-width
                    // CTA buttons elsewhere, e.g. auth/intro screens). As
                    // ListTile.trailing, that widget receives LOOSE
                    // constraints capped only at the tile's own width — so
                    // an unconstrained FilledButton tries to expand to
                    // infinity, gets clamped to exactly the tile's width,
                    // and trips ListTile's "trailing consumes the entire
                    // tile width" assertion. A plain SizedBox wrapper only
                    // masks this (it still relies on the tile always being
                    // wider than the box, which isn't guaranteed — e.g. a
                    // narrow split-view/foldable layout). Overriding
                    // minimumSize locally removes the infinite-width demand
                    // at its source, so this button can never trip that
                    // assertion regardless of available width.
                    trailing: amFollowing
                        ? null
                        : ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 90),
                            child: FilledButton.tonal(
                              onPressed: () => _followBack(f.userId),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                context.l10n.friendsFollow,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                  );
                },
              ),
            ),
    );
  }
}
