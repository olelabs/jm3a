import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/services/app_theme_service.dart';

/// Full-screen picker for the Game Card Color (items 5/6/8/9/10 of this
/// pass) — the color applied to the FRONT face of every game's shared
/// flip card (GameFlipCard, see lib/shared/widgets/game/game_flip_card.dart).
/// The back face never reflects this selection; it always keeps
/// AppThemeService.gameCardColors' first entry's look via
/// GameFlipCard's own hardcoded default, by design.
///
/// Unlike BackgroundColorScreen, this setting is local-only (SharedPreferences,
/// see AppThemeService.setGameCardColor) and not premium-gated, so there is
/// no server round-trip and no Save/Reset step: tapping a swatch applies and
/// persists immediately, the same way ThemePickerScreen's app-theme grid
/// already behaves.
class GameCardColorScreen extends StatelessWidget {
  const GameCardColorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final svc = context.watch<AppThemeService>();
    final selected = svc.currentGameCardColor;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.premiumGameCardColorTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              context.l10n.premiumGameCardColorHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _GameCardPreviewMockup(data: selected),
            const SizedBox(height: 20),
            Text(
              context.l10n.premiumChooseGameCardColor,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 108,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                // 0.76, not BackgroundColorScreen's 0.82 — this tile's
                // label is the same size but the extra cell height here
                // avoids a sub-pixel RenderFlex overflow under the color
                // names' actual rendered line height (e.g. "Sunset Orange").
                childAspectRatio: 0.76,
              ),
              itemCount: AppThemeService.gameCardColors.length,
              itemBuilder: (context, i) {
                final option = AppThemeService.gameCardColors[i];
                return _GameCardSwatchTile(
                  data: option,
                  selected: option.id == svc.gameCardColorId,
                  onTap: () => svc.setGameCardColor(option.id),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCardSwatchTile extends StatelessWidget {
  const _GameCardSwatchTile({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final GameCardColorData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.4, -0.7),
                    radius: 1.3,
                    colors: data.gradientColors,
                    stops: const [0.0, 0.55, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? data.borderGlowColor
                        : data.borderGlowColor.withValues(alpha: 0.4),
                    width: selected ? 2.5 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: data.borderGlowColor.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  scale: selected ? 1 : 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: selected ? 1 : 0,
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: data.borderGlowColor,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              gameCardColorLocalizedName(context, data.id),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? data.borderGlowColor
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A miniature stand-in for GameFlipCard's front face, using the exact same
/// gradient/border shape so the preview accurately represents the real card.
class _GameCardPreviewMockup extends StatelessWidget {
  const _GameCardPreviewMockup({required this.data});
  final GameCardColorData data;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.7),
            radius: 1.3,
            colors: data.gradientColors,
            stops: const [0.0, 0.55, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: data.borderGlowColor.withValues(alpha: 0.55),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: data.borderGlowColor.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.diamond_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  context.l10n.appName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Text(
              context.l10n.premiumChooseGameCardColor,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
