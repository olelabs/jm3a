import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../features/friends/data/friends_repository.dart' show FriendEntity;
import 'j_card.dart';
import 'user_avatar.dart';

/// One row in the Blocked list. Extracted from FriendsScreen's private
/// `_BlockedTab` into its own public, provider-free widget for the same
/// reason as ExplorePersonCard — a real widget test needs to render the
/// actual production card, not a reconstructed approximation, without
/// requiring a live Supabase-backed FriendsProvider.
class BlockedUserCard extends StatelessWidget {
  const BlockedUserCard({
    super.key,
    required this.user,
    required this.onUnblock,
  });

  final FriendEntity user;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return JCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          UserAvatar(
            avatarUrl: user.avatarUrl,
            avatarConfig: user.avatarConfig,
            displayName: user.displayName,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.displayName,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.username != null)
                  Text(
                    '@${user.username}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Explicit minimumSize:Size.zero — see ExplorePersonCard's
          // identical comment for why: the app-wide OutlinedButton theme
          // sets minimumSize: Size(double.infinity, 52); a non-Expanded
          // Row child receives an unbounded max width, so an unwrapped
          // themed button here throws "BoxConstraints forces an infinite
          // width" the instant this card renders.
          SizedBox(
            height: 34,
            child: OutlinedButton(
              onPressed: onUnblock,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                context.l10n.friendsUnblock,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
