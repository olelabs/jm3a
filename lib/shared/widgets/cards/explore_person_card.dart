import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/friends/data/friends_repository.dart'
    show ExplorePerson;
import 'honesty_score_line.dart';
import 'j_card.dart';
import 'user_avatar.dart';

/// One row in the Explore People feed. Extracted from
/// FriendsScreen's private `_ExploreCard` into its own public,
/// provider-free widget specifically so it can be rendered directly in a
/// real widget test (see test/friends_narrow_width_layout_test.dart) —
/// the actual production card, not a reconstructed approximation. Takes
/// plain callbacks instead of a live FriendsProvider so no
/// Supabase-backed singleton needs to exist for a test to pump this.
class ExplorePersonCard extends StatelessWidget {
  const ExplorePersonCard({
    super.key,
    required this.person,
    required this.hasSentRequest,
    required this.onAddFriend,
    this.isSending = false,
    this.onTap,
  });

  final ExplorePerson person;
  final bool hasSentRequest;
  final VoidCallback onAddFriend;

  /// True while this card's friend request is in flight — disables the
  /// button so a double tap can't send twice.
  final bool isSending;

  /// Opens this person's profile. Optional (defaults to no-op) only so
  /// existing tests/call sites that don't care about navigation don't
  /// need updating — every real call site should pass one; Explore is the
  /// one place in the app where a user can be discovered without already
  /// being a friend, so this is the entry point that most needed a way to
  /// view a profile before deciding whether to add them.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Item 8 — an incomplete (non-official) account must never render as
    // a normal discoverable user. ExplorePerson.isDiscoverable covers
    // this (official rows are always discoverable regardless of profile
    // completion — see that getter's own doc comment). FriendsProvider.
    // loadExplorePeople already filters this out before it ever reaches
    // this widget, but this is the shared, reusable card every caller
    // renders through — if it ever reaches this widget by some other path
    // regardless, it must still never render.
    if (!person.isDiscoverable) return const SizedBox.shrink();

    return JCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          UserAvatar(
            avatarUrl: person.avatarUrl,
            displayName: person.displayName,
            isOfficial: person.isOfficial,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        person.displayName,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (person.isOfficial) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: AppColors.infoBlue,
                      ),
                    ],
                  ],
                ),
                if (person.username != null)
                  Text(
                    '@${person.username}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                // Phase 1 (professional brand profile) — Jma3a Official
                // shows no player-reputation stats anywhere, including
                // here: this is a system/brand account, not a player.
                if (!person.isOfficial) ...[
                  const SizedBox(height: 6),
                  HonestyScoreLine(
                    honestyPoints: person.honestyPoints,
                    generalScore: person.generalScore,
                  ),
                ],
              ],
            ),
          ),
          // Jma3a Official is discoverable and followable (from its own
          // profile — see UserProfileScreen's official branch), but is
          // never a normal friend-request target: the server-side RLS
          // (20260901090700_block_official_account_friend_requests.sql)
          // already rejects it, and UserProfileScreen's own
          // canShowFriendRequestAction already hides this action there —
          // this card must not offer it either, mirroring that same rule
          // instead of relying on the RLS rejection alone.
          if (!person.isOfficial) ...[
            const SizedBox(width: 8),
            // Explicit minimumSize:Size.zero + shrinkWrap tap target — the
            // app-wide FilledButton theme sets minimumSize:
            // Size(double.infinity, 52) (for full-width primary CTAs), and
            // this button is a non-Expanded Row child, which receives an
            // UNBOUNDED max width from the Row regardless of this
            // SizedBox's own (height-only) constraint — without this style
            // override it throws "BoxConstraints forces an infinite width"
            // the instant a card with an eligible (not yet requested)
            // person renders.
            hasSentRequest
                // ConstrainedBox+ellipsis — "Request Sent" is longer than
                // "Add Friend", and a Chip's label has no shrink/overflow
                // protection of its own: at the narrowest reported width
                // (320px) with a long display name squeezing this column,
                // the unconstrained label alone was enough to throw
                // "A RenderFlex overflowed by N pixels" (see
                // HonestyScoreLine's identical class of bug/fix above it in
                // this same card).
                ? Chip(
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 90),
                      child: Text(
                        context.l10n.exploreRequestSent,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                  )
                : SizedBox(
                    height: 34,
                    child: FilledButton.tonal(
                      onPressed: isSending ? null : onAddFriend,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.l10n.exploreAddFriend),
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}
