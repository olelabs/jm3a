import 'package:flutter/material.dart';

import 'core/extensions/context_ext.dart';
import 'features/avatar/presentation/avatar_creator_screen.dart';

const kStickerAssets = <String>[
  'assets/images/stickers/sticker_01.jpg',
  'assets/images/stickers/sticker_02.jpg',
  'assets/images/stickers/sticker_03.jpg',
  'assets/images/stickers/sticker_04.jpg',
  'assets/images/stickers/sticker_05.jpg',
  'assets/images/stickers/sticker_06.jpg',
  'assets/images/stickers/sticker_07.jpg',
  'assets/images/stickers/sticker_08.jpg',
  'assets/images/stickers/sticker_09.jpg',
  'assets/images/stickers/sticker_10.jpg',
  'assets/images/stickers/sticker_11.jpg',
  'assets/images/stickers/sticker_12.jpg',
];

// Item 6 (reaction-expansion pass) — the original 21 reactions below are
// kept byte-for-byte in their original order (their literal string VALUE
// is the reaction's stable id — see AnimatedReactionOverlay/EmojiReactionRow,
// which key everything off this exact string, never a list index) so no
// existing reaction anyone has ever sent changes identity. Every new
// reaction is appended after them, never inserted, for the same reason.
const kEmojiReactions = [
  '😂',
  '❤️',
  '🔥',
  '💀',
  '👏',
  '🤣',
  '😭',
  '🫡',
  '💯',
  '🤯',
  '👑',
  '😤',
  '🥹',
  '🫶',
  '💅',
  '🙈',
  '😎',
  '🤡',
  '💔',
  '🎉',
  '😈',
  // New reactions (this pass) — curated, no duplicates of the 21 above.
  // Most of these already have a real animated_emoji asset mapped in
  // kAnimatedEmojiMap (animated_reaction_overlay.dart); the rest render
  // as a plain glyph via the exact same fallback path every existing
  // unmapped reaction (e.g. 👑) already uses.
  '😍',
  '🤩',
  '🥳',
  '😘',
  '💖',
  '✨',
  '🌟',
  '🌈',
  '🏆',
  '👍',
  '🤝',
  '🤞',
  '👀',
  '😆',
  '😉',
  '😏',
  '🫠',
  '🤠',
  '😲',
  '😳',
  '🙄',
  '😠',
  '😔',
  '🥺',
  '🎯',
  '😹',
];

/// Item 6 (this pass) — labeled groupings of [kEmojiReactions] purely for
/// the picker's own organized browsing (`_ReactionPickerSheet`); every
/// other consumer of reactions (the flying overlay, the quick-react row,
/// stored reaction events) keeps reading the flat [kEmojiReactions] list
/// exactly as before — this mapping doesn't change what a reaction IS,
/// only how the picker groups it visually. Every emoji in
/// [kEmojiReactions] appears in exactly one category below — verified by
/// a dedicated test (see test/emoji_reaction_categories_test.dart) rather
/// than a runtime check, since this is a fixed compile-time constant.
const Map<String, List<String>> kEmojiReactionCategories = {
  'popular': ['😂', '❤️', '🔥', '💀', '👏', '💯', '🎉', '👍'],
  'love': ['😍', '🤩', '😘', '💖', '🫶', '💅'],
  'funny': ['🤣', '🤡', '😏', '🫠', '🤠', '😉', '😆', '🙈'],
  'shock': ['🤯', '😲', '😳', '🙄'],
  'celebration': ['🥳', '🏆', '🌟', '✨', '🌈', '👑'],
  'social': ['🫡', '🤝', '🤞', '👀', '😎', '😹', '🎯'],
  'moody': ['😭', '😤', '🥹', '💔', '😔', '🥺', '😠', '😈'],
};

class StickerImage extends StatelessWidget {
  const StickerImage({
    super.key,
    required this.assetPath,
    this.size = 60,
    this.selected = false,
    this.onTap,
  });

  final String assetPath;
  final double size;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: theme.colorScheme.primary, width: 2.5)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(selected ? 8 : 10),
          child: assetPath.startsWith('http')
              ? Image.network(
                  assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: size * 0.4,
                    ),
                  ),
                )
              : Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    final idx = kStickerAssets.indexOf(assetPath) + 1;
                    return Center(
                      child: Text(
                        '🎭$idx',
                        style: TextStyle(fontSize: size * 0.4),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class StickerPicker extends StatelessWidget {
  const StickerPicker({
    super.key,
    required this.selected,
    required this.onSelect,
    this.stickerSize = 64,
    this.customUrls,
  });

  final String? selected;
  final ValueChanged<String> onSelect;
  final double stickerSize;
  final List<String>? customUrls;

  @override
  Widget build(BuildContext context) {
    final items = customUrls ?? kStickerAssets;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final path = items[i];
        return StickerImage(
          assetPath: path,
          size: stickerSize,
          selected: selected == path,
          onTap: () => onSelect(selected == path ? '' : path),
        );
      },
    );
  }
}

class StickerDisplay extends StatelessWidget {
  const StickerDisplay({super.key, required this.assetPath, this.size = 56});
  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return StickerImage(assetPath: assetPath, size: size);
  }
}

// Item 6 (reaction-expansion pass) — same stability guarantee as
// kEmojiReactions above: the original 12 keys stay first and unchanged
// (an avatar reaction's id is 'avatar:<key>' — see AvatarConfig.
// isAvatarReaction/avatarReactionKey — so a key rename would break every
// already-sent reaction of that kind), new keys only ever appended.
const kReactionKeys = [
  'laugh',
  'fire',
  'dead',
  'clap',
  'rofl',
  'cry',
  'salute',
  'hundred',
  'mindblown',
  'crown',
  'annoyed',
  'touched',
  // New (this pass) — see AvatarConfig.reactionExpressions for each
  // key's actual eye/mouth/eyebrow combination.
  'love',
  'wink',
  'silly',
  'dizzy',
  'sad',
  'shocked',
  'confident',
  'grumpy',
  'sleepy',
  'starstruck',
  'yum',
  'unimpressed',
];

class ReactionDisplay extends StatelessWidget {
  const ReactionDisplay({
    super.key,
    required this.value,
    this.size = 18,
    this.avatarConfig,
  });

  final String value;
  final double size;
  final Map<String, dynamic>? avatarConfig;

  @override
  Widget build(BuildContext context) {
    if (AvatarConfig.isAvatarReaction(value) && avatarConfig != null) {
      final key = AvatarConfig.avatarReactionKey(value);
      final url = AvatarConfig.fromMap(avatarConfig!).reactionUrl(key);
      return ClipOval(
        child: AvatarDisplay(avatarUrl: url, size: size * 1.6),
      );
    }
    final display = AvatarConfig.isAvatarReaction(value)
        ? (AvatarConfig
                  .reactionExpressions[AvatarConfig.avatarReactionKey(value)]
                  ?.emoji ??
              '🙂')
        : value;
    return Text(display, style: TextStyle(fontSize: size));
  }
}

class EmojiReactionRow extends StatelessWidget {
  const EmojiReactionRow({
    super.key,
    required this.reactionsByEmoji,
    required this.alreadyReacted,
    required this.onReact,
    this.useAvatarMode = false,
    this.ownAvatarConfig,
    this.avatarConfigByValue = const {},
  });

  final Map<String, int> reactionsByEmoji;
  final bool alreadyReacted;
  final ValueChanged<String> onReact;
  final bool useAvatarMode;
  final Map<String, dynamic>? ownAvatarConfig;
  final Map<String, Map<String, dynamic>?> avatarConfigByValue;

  bool get _hasAvatars => useAvatarMode && ownAvatarConfig != null;

  void _openPicker(BuildContext context, {required bool avatars}) {
    final items = avatars
        ? kReactionKeys.map((k) => '${AvatarConfig.reactionPrefix}$k').toList()
        : kEmojiReactions;
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _ReactionPickerSheet(
        title: avatars
            ? l10n.sharedReactionPickAvatarTitle
            : l10n.sharedReactionPickIconTitle,
        items: items,
        // Item 6 (this pass) — only the plain-emoji picker groups into
        // categories; the avatar grid has no category concept of its
        // own, so it keeps the flat grid it already had (still fully
        // scrollable at the new, larger size — see _ReactionPickerSheet).
        categories: avatars ? null : kEmojiReactionCategories,
        avatarConfig: avatars ? ownAvatarConfig : null,
        onPick: (value) {
          Navigator.of(sheetCtx).pop();
          onReact(value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reactionsByEmoji.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: reactionsByEmoji.entries
                .map(
                  (e) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReactionDisplay(
                          value: e.key,
                          size: 14,
                          avatarConfig: avatarConfigByValue[e.key],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${e.value}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),

        if (!alreadyReacted) ...[
          if (reactionsByEmoji.isNotEmpty) const SizedBox(height: 6),
          if (_hasAvatars)
            // Two large, clearly-separated entry points instead of icons
            // and avatars mixed into one scrollable row — each opens its
            // own big-tile picker.
            Row(
              children: [
                Expanded(
                  child: _ReactionModeButton(
                    label: context.l10n.sharedReactionIconsTab,
                    leading: const Text('😀', style: TextStyle(fontSize: 20)),
                    onTap: () => _openPicker(context, avatars: false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ReactionModeButton(
                    label: context.l10n.sharedReactionAvatarsTab,
                    leading: const Text('👤', style: TextStyle(fontSize: 20)),
                    onTap: () => _openPicker(context, avatars: true),
                  ),
                ),
              ],
            )
          else
            // No avatars available for this user — unchanged icon-only
            // scrollable row.
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: kEmojiReactions
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => onReact(s),
                          child: Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: ReactionDisplay(value: s, size: 18),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ],
    );
  }
}

/// One of the two large "Icons" / "Avatars" entry-point buttons.
class _ReactionModeButton extends StatelessWidget {
  const _ReactionModeButton({
    required this.label,
    required this.leading,
    required this.onTap,
  });

  final String label;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item 6 (reaction-expansion pass) — resolves a category id (a key of
/// [kEmojiReactionCategories]) to its localized display label.
String _categoryLabel(BuildContext context, String categoryId) {
  final l10n = context.l10n;
  return switch (categoryId) {
    'popular' => l10n.sharedReactionCategoryPopular,
    'love' => l10n.sharedReactionCategoryLove,
    'funny' => l10n.sharedReactionCategoryFunny,
    'shock' => l10n.sharedReactionCategoryShock,
    'celebration' => l10n.sharedReactionCategoryCelebration,
    'social' => l10n.sharedReactionCategorySocial,
    'moody' => l10n.sharedReactionCategoryMoody,
    _ => categoryId,
  };
}

/// Large-tile grid picker opened by either mode button — same sheet shape
/// for icons and avatars, just a different item set.
///
/// Item 6 (this pass) — [items] grew substantially (kEmojiReactions:
/// 21 → 47; the avatar set: 12 → 24), so the old shrinkWrap-everything
/// GridView (sized to fit ALL rows, no matter how tall) risked a real
/// overflow on a short/narrow phone. The whole sheet now caps itself at
/// a fraction of the screen height and scrolls its own content — via a
/// real scrollable ([categories] != null: a ListView of labeled
/// sections; null: the same flat grid as before, just now genuinely
/// scrollable) — instead of only ever growing to fit.
class _ReactionPickerSheet extends StatelessWidget {
  const _ReactionPickerSheet({
    required this.title,
    required this.items,
    required this.onPick,
    this.avatarConfig,
    this.categories,
  });

  final String title;
  final List<String> items;
  final Map<String, dynamic>? avatarConfig;
  final ValueChanged<String> onPick;

  /// When set, [items] is rendered as labeled sections (this category's
  /// items filtered against [items] so an id present in a category but
  /// absent from [items] — shouldn't happen, but defensively — never
  /// renders a broken tile). When null, falls back to one flat grid.
  final Map<String, List<String>>? categories;

  Widget _tile(BuildContext context, String value, {required double size}) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onPick(value),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: ReactionDisplay(
              value: value,
              size: size * 0.55,
              avatarConfig: avatarConfig,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.72;
    final cats = categories;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: cats == null
                  ? GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _tile(context, items[i], size: 64),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final entry in cats.entries)
                          if (entry.value.any(items.contains)) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 10,
                                bottom: 8,
                              ),
                              child: Text(
                                _categoryLabel(context, entry.key),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final value in entry.value)
                                  if (items.contains(value))
                                    _tile(context, value, size: 56),
                              ],
                            ),
                          ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
