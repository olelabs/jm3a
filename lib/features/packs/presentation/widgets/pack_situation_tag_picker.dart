import 'package:flutter/material.dart';

import '../../domain/pack_situation_tags.dart';

/// Shared multi-select chip cloud for the curated situation vocabulary
/// (kPackSituationTags) — the ONE picker UI reused by both the lobby's
/// "what are you looking for" filter (game_settings_sheet.dart) and pack
/// creation's optional type selector (create_pack_screen.dart), so both
/// surfaces present the exact same recognized values.
class PackSituationTagPicker extends StatelessWidget {
  const PackSituationTagPicker({
    super.key,
    required this.title,
    this.subtitle,
    required this.tags,
    required this.selected,
    required this.onToggle,
  });

  final String title;
  final String? subtitle;

  /// The DB-driven (item 7) active filter vocabulary — loaded by the
  /// caller via PackRepository.getSituationFilters, not fetched by this
  /// widget, so both this picker and any other consumer can share one
  /// fetch and this stays a plain presentational widget.
  final List<PackSituationTag> tags;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            final isSelected = selected.contains(tag.slug);
            return InkWell(
              onTap: () => onToggle(tag.slug),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.14)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    width: 1.4,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tag.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      tag.label(context),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
