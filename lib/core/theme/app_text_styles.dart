import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// Jma3a Typography System
/// ═══════════════════════════════════════════════════════════════
///
/// Scale: 11 / 12 / 13 / 14 / 16 / 18 / 22 / 28 / 36 / 48
/// Line height: 1.2 (tight — display) → 1.5 (relaxed — body)
///
/// Latin: Inter (system fallback) — replace google_fonts at build time
///   with --dart-define. Loaded from assets/fonts/Inter-*.ttf.
/// Arabic: Cairo — bundled in assets/fonts/Cairo-*.ttf
/// French: Inter (same as Latin)
///
/// Weight usage:
///   400 Regular — body copy
///   500 Medium  — labels, secondary headings
///   600 SemiBold— screen titles, card headings
///   700 Bold    — display, game card content, CTAs
///   800 ExtraBold— game choice buttons (TRUTH / DARE), hero numbers
abstract final class AppTextStyles {
  static const String _latinFamily  = 'Inter';
  static const String _arabicFamily = 'Cairo';

  static String familyForLocale(Locale? locale) =>
      locale?.languageCode == 'ar' ? _arabicFamily : _latinFamily;

  /// Full TextTheme using the brand scale.
  static TextTheme textTheme(ColorScheme cs, {String? fontFamily}) {
    final family  = fontFamily ?? _latinFamily;
    final primary = cs.onSurface;
    final muted   = cs.onSurfaceVariant;

    return TextTheme(
      // ── Display — hero numbers, game-over screens ─────────────────────
      displayLarge:  _t(48, 700, primary,  family, tight: true),
      displayMedium: _t(36, 700, primary,  family, tight: true),
      displaySmall:  _t(28, 600, primary,  family, tight: true),

      // ── Headline — screen titles, section heads ───────────────────────
      headlineLarge:  _t(28, 600, primary, family, tight: true),
      headlineMedium: _t(22, 600, primary, family),
      headlineSmall:  _t(18, 600, primary, family),

      // ── Title — card headings, list primaries ─────────────────────────
      titleLarge:  _t(18, 600, primary, family),
      titleMedium: _t(16, 500, primary, family),
      titleSmall:  _t(14, 500, primary, family),

      // ── Body — main content ───────────────────────────────────────────
      bodyLarge:  _t(16, 400, primary, family, relaxed: true),
      bodyMedium: _t(14, 400, primary, family, relaxed: true),
      bodySmall:  _t(12, 400, muted,   family, relaxed: true),

      // ── Label — buttons, chips, badges, metadata ──────────────────────
      labelLarge:  _t(16, 600, primary, family),
      labelMedium: _t(14, 500, primary, family),
      labelSmall:  _t(11, 500, muted,   family),
    );
  }

  // ── Game-specific text styles (not in TextTheme) ──────────────────────

  /// Truth / Dare choice button labels — massive, heavy
  static TextStyle gameChoiceLabel({required Color color}) =>
      _t(28, 800, color, _latinFamily, tight: true);

  /// Card content text — readable, comfortable line height
  static TextStyle gameCardContent({required Color color}) =>
      _t(20, 700, color, _latinFamily)
          .copyWith(height: 1.45, shadows: [
        Shadow(color: color.withOpacity(0.15),
               blurRadius: 8, offset: const Offset(0, 2))
      ]);

  /// Player name in turn banner — confident, but not huge
  static TextStyle playerName({required Color color}) =>
      _t(22, 700, color, _latinFamily, tight: true);

  /// Round counter / HUD label — uppercase, tracked
  static TextStyle hudLabel({required Color color}) =>
      _t(11, 600, color, _latinFamily)
          .copyWith(letterSpacing: 0.8, height: 1.2);

  /// Balance display in wallet — tabular numerics
  static TextStyle walletBalance({required Color color}) =>
      _t(36, 800, color, _latinFamily, tight: true)
          .copyWith(fontFeatures: [const FontFeature.tabularFigures()]);

  /// Leaderboard rank number
  static TextStyle rankNumber({required Color color}) =>
      _t(48, 800, color, _latinFamily, tight: true);

  // ── Builder ───────────────────────────────────────────────────────────
  static TextStyle _t(
    double size,
    int weight,
    Color color,
    String family, {
    bool tight   = false,
    bool relaxed = false,
  }) =>
      TextStyle(
        fontFamily:   family,
        fontSize:     size,
        fontWeight:   FontWeight.values.firstWhere(
          (w) => w.index * 100 == weight,
          orElse: () => FontWeight.w400,
        ),
        color:        color,
        height:       tight ? 1.2 : relaxed ? 1.55 : 1.4,
        letterSpacing: size >= 28 ? -0.5 : size >= 18 ? -0.2 : 0,
      );
}
