import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/services/app_theme_service.dart';
import '../../profile/presentation/profile_provider.dart';

/// A curated, theme-safe background option. Deliberately neutral/low-chroma
/// so it blends under any of the app's saturated theme primaries (Neon,
/// Candy, Galaxy, ...) instead of competing with them. Add more entries
/// here to extend the palette — nothing else needs to change.
class _BackgroundOption {
  const _BackgroundOption(this.name, this.color);
  final String name;
  final Color color;
}

const List<_BackgroundOption> _backgroundPalette = [
  _BackgroundOption('White', Color(0xFFFFFFFF)),
  _BackgroundOption('Warm White', Color(0xFFFAF6F0)),
  _BackgroundOption('Light Grey', Color(0xFFE9E9EA)),
  _BackgroundOption('Cool Grey', Color(0xFFDEE2E6)),
  _BackgroundOption('Charcoal', Color(0xFF2F3136)),
  _BackgroundOption('Soft Black', Color(0xFF1B1B1D)),
  _BackgroundOption('Cream', Color(0xFFF6F1E4)),
  _BackgroundOption('Beige', Color(0xFFE8DCC4)),
  _BackgroundOption('Sand', Color(0xFFE0D2AE)),
  _BackgroundOption('Stone', Color(0xFFD8D3C4)),
  _BackgroundOption('Slate', Color(0xFF6E7B8B)),
  _BackgroundOption('Navy Grey', Color(0xFF3C4656)),
  _BackgroundOption('Deep Blue Grey', Color(0xFF2B333E)),
  _BackgroundOption('Forest Mist', Color(0xFFDCE6DD)),
  _BackgroundOption('Sage', Color(0xFFC3D0BE)),
  _BackgroundOption('Pale Blue', Color(0xFFDCE8F2)),
  _BackgroundOption('Mist Blue', Color(0xFFCFE0EA)),
  _BackgroundOption('Lavender Mist', Color(0xFFE6E1F2)),
  _BackgroundOption('Blush', Color(0xFFF3E1E3)),
  _BackgroundOption('Soft Mint', Color(0xFFDCF0E6)),
  _BackgroundOption('Graphite', Color(0xFF3A3A3C)),
];

/// Full-screen replacement for the former Background Color modal bottom
/// sheet. Selection is a curated, theme-safe palette (no free color picker)
/// so every option is guaranteed to preserve readability, button/icon
/// visibility, and contrast against any of the app's themes.
class BackgroundColorScreen extends StatefulWidget {
  const BackgroundColorScreen({super.key, required this.initialColor});

  final Color initialColor;

  @override
  State<BackgroundColorScreen> createState() => _BackgroundColorScreenState();
}

class _BackgroundColorScreenState extends State<BackgroundColorScreen> {
  late final ValueNotifier<Color> _localPreview = ValueNotifier(
    widget.initialColor,
  );
  bool _saving = false;
  bool _saved = false;

  @override
  void dispose() {
    // Any exit path that didn't go through a successful Save (back button,
    // app bar back arrow, system back gesture, or any other pop) leaves the
    // app-wide preview reverted to whatever's actually persisted, never
    // stuck on an unsaved color. Save/Reset already clear it themselves on
    // success before popping, so _saved guards against double-clearing —
    // clearPreviewBackground() is idempotent either way, but this keeps the
    // intent explicit.
    if (!_saved) {
      AppThemeService.instance.clearPreviewBackground();
    }
    _localPreview.dispose();
    super.dispose();
  }

  void _selectColor(Color c) {
    // A tap is a single, discrete selection (unlike a picker drag), so both
    // the on-screen mockup and the real app-wide preview update in the same
    // frame — no need to throttle/defer to a "change end" event.
    _localPreview.value = c;
    context.read<AppThemeService>().previewBackground(c);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final c = _localPreview.value;
    final hex =
        '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    final ok = await context.read<ProfileProvider>().setThemeBackgroundColor(
      hex,
    );
    if (!mounted) return;
    if (ok) {
      _saved = true;
      context.read<AppThemeService>().clearPreviewBackground();
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
      context.showErrorSnackBar(
        context.read<ProfileProvider>().lastFailure?.message ??
            'Could not save background color.',
      );
    }
  }

  Future<void> _reset() async {
    setState(() => _saving = true);
    final ok = await context.read<ProfileProvider>().setThemeBackgroundColor(
      null,
    );
    if (!mounted) return;
    if (ok) {
      _saved = true;
      context.read<AppThemeService>().clearPreviewBackground();
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
      context.showErrorSnackBar(
        context.read<ProfileProvider>().lastFailure?.message ??
            'Could not reset background color.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Scaffold(
      appBar: AppBar(title: const Text('Background Color')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Blends into your selected theme — text, cards, and '
                      'icons adapt automatically.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Local, cheap, per-tap preview.
                    ValueListenableBuilder<Color>(
                      valueListenable: _localPreview,
                      builder: (_, c, _) => _BackgroundPreviewMockup(color: c),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Choose a background',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<Color>(
                      valueListenable: _localPreview,
                      builder: (_, selected, _) => GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 108,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.82,
                            ),
                        itemCount: _backgroundPalette.length,
                        itemBuilder: (context, i) {
                          final option = _backgroundPalette[i];
                          return _SwatchTile(
                            option: option,
                            selected: _colorsMatch(selected, option.color),
                            onTap: () => _selectColor(option.color),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    Flexible(
                      child: TextButton(
                        onPressed: _saving ? null : _reset,
                        child: const Text(
                          'Reset to Default',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Expanded (not just Flexible) is load-bearing here: the
                    // app-wide FilledButtonThemeData sets
                    // minimumSize: Size(double.infinity, 52) so every filled
                    // button defaults to full-width. Inside a bare Row that
                    // combines with the Row's own unbounded-width child
                    // constraints and throws "BoxConstraints forces an
                    // infinite width". Expanded gives it a concrete, bounded
                    // width to fill instead.
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _colorsMatch(Color a, Color b) => a.toARGB32() == b.toARGB32();

/// One selectable palette swatch: a rounded color square with a checkmark
/// badge when selected, plus its label. The tile's own chrome (background,
/// label text) stays on the screen's normal theme — only the square shows
/// the candidate background color — so labels never fight for contrast
/// against whichever swatch they describe.
class _SwatchTile extends StatelessWidget {
  const _SwatchTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _BackgroundOption option;
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
                  color: option.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: selected ? 2.5 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.35,
                            ),
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
                          color: theme.colorScheme.primary,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundPreviewMockup extends StatelessWidget {
  const _BackgroundPreviewMockup({required this.color});
  final Color color;

  // Mirrors AppTheme._deriveSurfaceFamily's blend tiers so this preview is
  // an accurate stand-in for how the real app derives its surfaces from a
  // chosen background: cards sit a small, fixed step above the background,
  // never as loud as the button.
  static Color _contrastFor(Color c) => c.computeLuminance() > 0.35
      ? const Color(0xFF1A1A1A)
      : const Color(0xFFFFFFFF);

  static Color _blend(Color background, double amount) =>
      Color.alphaBlend(_contrastFor(background).withValues(alpha: amount), background);

  @override
  Widget build(BuildContext context) {
    // Card/border/text are derived from the *chosen background*, not the
    // ambient theme, so this mockup demonstrates exactly what applying that
    // background would do to the app's surfaces. The button intentionally
    // uses the *current active theme's* primary color — that's the one
    // piece that stays constant regardless of background choice, and it
    // must always read as the most prominent element on the page.
    final activeTheme = context.theme;
    final ink = _contrastFor(color);
    final cardColor = _blend(color, 0.08);
    final cardBorder = _blend(color, 0.16);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Page background',
            style: TextStyle(
              color: ink,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.favorite_rounded, color: ink, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Card text stays readable',
                    style: TextStyle(color: ink, fontWeight: FontWeight.w600),
                  ),
                ),
                FilledButton(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    backgroundColor: activeTheme.colorScheme.primary,
                    disabledBackgroundColor: activeTheme.colorScheme.primary,
                    foregroundColor: activeTheme.colorScheme.onPrimary,
                    disabledForegroundColor:
                        activeTheme.colorScheme.onPrimary,
                  ),
                  child: const Text('Action'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
