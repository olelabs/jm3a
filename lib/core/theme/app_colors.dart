// import 'package:flutter/material.dart';

// /// ═══════════════════════════════════════════════════════════════
// /// Jma3a Design System — Color Tokens
// /// ═══════════════════════════════════════════════════════════════
// ///
// /// Brand identity: playful, social, modern.
// /// Primary: Electric Blue  — trust, clarity, multiplayer energy
// /// Accent:  Vivid Orange   — warmth, excitement, social energy
// /// Support: Deep Purple    — premium, fun, game-specific highlights
// ///
// /// Usage hierarchy:
// ///   1. Use ColorScheme tokens (context.colorScheme.primary) in widgets
// ///   2. Use JColors theme extension for Jma3a-specific semantic colors
// ///   3. AppColors is RAW palette — only use in AppTheme construction
// ///
// /// NEVER use AppColors hex values directly in UI widgets.
// abstract final class AppColors {

//   // ── Brand: Electric Blue ─────────────────────────────────────────────
//   /// Deep navy — primary brand, headers, CTAs in light mode
//   static const brandBlueDark     = Color(0xFF1B3A5C);
//   /// Mid blue — primary in dark mode, links
//   static const brandBlueMid      = Color(0xFF2D5F9E);
//   /// Electric blue — high-energy accents, game highlights
//   static const brandBlueElectric = Color(0xFF3B82F6);
//   /// Soft blue — containers, backgrounds
//   static const brandBlueLight    = Color(0xFFDBEAFE);

//   // ── Brand: Vivid Orange ──────────────────────────────────────────────
//   /// Deep amber — CTA highlights, active states
//   static const brandOrangeDark   = Color(0xFFEA580C);
//   /// Vivid orange — badges, notifications, energy
//   static const brandOrangeMid    = Color(0xFFF97316);
//   /// Soft orange — containers, warm backgrounds
//   static const brandOrangeLight  = Color(0xFFFFEDD5);

//   // ── Brand: Deep Purple ───────────────────────────────────────────────
//   /// Deep purple — premium feel, game cards, special states
//   static const brandPurpleDark   = Color(0xFF4F46E5);
//   /// Mid purple — game accents, social badges
//   static const brandPurpleMid    = Color(0xFF7C3AED);
//   /// Soft purple — containers
//   static const brandPurpleLight  = Color(0xFFEDE9FE);

//   // ── Neutrals ─────────────────────────────────────────────────────────
//   static const neutral900 = Color(0xFF0F172A);
//   static const neutral800 = Color(0xFF1E293B);
//   static const neutral700 = Color(0xFF334155);
//   static const neutral600 = Color(0xFF475569);
//   static const neutral500 = Color(0xFF64748B);
//   static const neutral400 = Color(0xFF94A3B8);
//   static const neutral300 = Color(0xFFCBD5E1);
//   static const neutral200 = Color(0xFFE2E8F0);
//   static const neutral100 = Color(0xFFF1F5F9);
//   static const neutral50  = Color(0xFFF8FAFC);
//   static const white      = Color(0xFFFFFFFF);
//   static const black      = Color(0xFF000000);

//   // ── Dark surfaces ────────────────────────────────────────────────────
//   static const darkBase         = Color(0xFF0B1120);  // app background
//   static const darkSurface      = Color(0xFF111827);  // cards, sheets
//   static const darkElevated     = Color(0xFF1A2535);  // elevated cards
//   static const darkHighest      = Color(0xFF1F2E42);  // inputs, chips

//   // ── Semantic ─────────────────────────────────────────────────────────
//   static const successGreen    = Color(0xFF16A34A);
//   static const successLight    = Color(0xFFDCFCE7);
//   static const warningAmber    = Color(0xFFD97706);
//   static const warningLight    = Color(0xFFFEF3C7);
//   static const errorRed        = Color(0xFFDC2626);
//   static const errorLight      = Color(0xFFFEE2E2);
//   static const infoBlue        = Color(0xFF2563EB);
//   static const infoLight       = Color(0xFFDBEAFE);

//   // ── Game-specific ────────────────────────────────────────────────────
//   static const truthBlue      = Color(0xFF3B82F6);
//   static const truthBlueDark  = Color(0xFF1D4ED8);
//   static const dareRed        = Color(0xFFEF4444);
//   static const dareDark       = Color(0xFFB91C1C);
//   static const nhieGreen      = Color(0xFF059669);
//   static const memeYellow     = Color(0xFFF59E0B);
//   static const spicyOrange    = Color(0xFFEA580C);
//   static const ownerGold      = Color(0xFFF59E0B);
//   static const modBadge       = Color(0xFF7C3AED);

//   // ── Borders ──────────────────────────────────────────────────────────
//   static const borderLight    = Color(0xFFE2E8F0);
//   static const borderSubtle   = Color(0xFFF1F5F9);
//   static const borderDark     = Color(0xFF1F2E42);
//   static const borderDarkSub  = Color(0xFF172436);
// }

// // ─── Spacing: strict 4pt grid ─────────────────────────────────────────────────
// abstract final class AppSpacing {
//   static const double px2  = 2;
//   static const double px4  = 4;   // xs
//   static const double px6  = 6;
//   static const double px8  = 8;   // sm
//   static const double px10 = 10;
//   static const double px12 = 12;  // md-small
//   static const double px14 = 14;
//   static const double px16 = 16;  // md
//   static const double px20 = 20;
//   static const double px24 = 24;  // lg
//   static const double px28 = 28;
//   static const double px32 = 32;  // xl
//   static const double px40 = 40;
//   static const double px48 = 48;  // xxl
//   static const double px56 = 56;
//   static const double px64 = 64;  // xxxl

//   // Semantic aliases
//   static const double xs   = px4;
//   static const double sm   = px8;
//   static const double md   = px16;
//   static const double lg   = px24;
//   static const double xl   = px32;
//   static const double xxl  = px48;
//   static const double xxxl = px64;

//   // Screen edge padding (thumb-friendly horizontal margins)
//   static const double screenH  = px20;  // horizontal screen padding
//   static const double screenV  = px24;  // vertical screen padding
//   static const double section  = px32;  // section spacing
// }

// // ─── Border radius ─────────────────────────────────────────────────────────────
// abstract final class AppRadius {
//   static const double xs   = 4;
//   static const double sm   = 8;
//   static const double md   = 12;
//   static const double lg   = 16;
//   static const double xl   = 20;
//   static const double xxl  = 24;
//   static const double xxxl = 32;

//   // Semantic
//   static const double button    = 12;
//   static const double card      = 16;
//   static const double sheet     = 24;  // bottom sheets
//   static const double dialog    = 20;
//   static const double input     = 12;
//   static const double chip      = 8;
//   static const double badge     = 999; // pill
//   static const double avatar    = 999; // circle

//   static BorderRadius get cardRR => BorderRadius.circular(card);
//   static BorderRadius get buttonRR => BorderRadius.circular(button);
//   static BorderRadius get sheetRR =>
//       const BorderRadius.vertical(top: Radius.circular(sheet));
// }

// // ─── Elevation / shadow system ─────────────────────────────────────────────────
// /// Jma3a uses colored shadows (brand-tinted) instead of grey.
// /// Elevation is expressed as shadow prominence — no actual elevation needed.
// abstract final class AppShadows {
//   // Subtle — cards at rest
//   static List<BoxShadow> card(Color color) => [
//     BoxShadow(
//       color: color.withOpacity(0.04),
//       blurRadius: 8,
//       offset: const Offset(0, 2),
//     ),
//     BoxShadow(
//       color: color.withOpacity(0.06),
//       blurRadius: 16,
//       offset: const Offset(0, 4),
//     ),
//   ];

//   // Medium — floating buttons, active cards
//   static List<BoxShadow> elevated(Color color) => [
//     BoxShadow(
//       color: color.withOpacity(0.12),
//       blurRadius: 20,
//       offset: const Offset(0, 6),
//     ),
//     BoxShadow(
//       color: color.withOpacity(0.08),
//       blurRadius: 8,
//       offset: const Offset(0, 2),
//     ),
//   ];

//   // Strong — FABs, primary CTAs, game cards
//   static List<BoxShadow> prominent(Color color) => [
//     BoxShadow(
//       color: color.withOpacity(0.25),
//       blurRadius: 24,
//       offset: const Offset(0, 8),
//     ),
//     BoxShadow(
//       color: color.withOpacity(0.12),
//       blurRadius: 8,
//       offset: const Offset(0, 2),
//     ),
//   ];

//   // Glow — game choice buttons, highlighted states
//   static List<BoxShadow> glow(Color color) => [
//     BoxShadow(
//       color: color.withOpacity(0.40),
//       blurRadius: 32,
//       spreadRadius: -4,
//       offset: const Offset(0, 8),
//     ),
//   ];

//   // None — flat cards (when border is used instead)
//   static const List<BoxShadow> none = [];
// }

// // ─── Duration constants ─────────────────────────────────────────────────────────
// /// All animations use these — no magic numbers in widget code.
// abstract final class AppDuration {
//   static const instant  = Duration(milliseconds: 0);
//   static const fast     = Duration(milliseconds: 120);
//   static const normal   = Duration(milliseconds: 220);
//   static const medium   = Duration(milliseconds: 350);
//   static const slow     = Duration(milliseconds: 500);
//   static const xslow    = Duration(milliseconds: 700);

//   // Page transitions
//   static const pageEnter = Duration(milliseconds: 280);
//   static const pageExit  = Duration(milliseconds: 200);

//   // Game-specific
//   static const cardFlip   = Duration(milliseconds: 400);
//   static const turnReveal = Duration(milliseconds: 550);
//   static const celebration = Duration(milliseconds: 700);
// }

// // ─── Curve constants ──────────────────────────────────────────────────────────
// abstract final class AppCurves {
//   // Standard
//   static const standard  = Curves.easeInOutCubic;
//   static const enter     = Curves.easeOutCubic;
//   static const exit      = Curves.easeInCubic;

//   // Spring-like — for card reveals, game interactions
//   static const spring    = Curves.easeOutBack;
//   static const springIn  = Curves.easeInBack;

//   // Emphasised — game turn transitions, celebrations
//   static const pop       = Curves.elasticOut;

//   // Decelerate — most commonly used
//   static const decel     = Curves.decelerate;
// }

import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// Jma3a Design System — Color Tokens
/// ═══════════════════════════════════════════════════════════════
///
/// Brand identity: playful, social, modern.
/// Primary: Electric Blue  — trust, clarity, multiplayer energy
/// Accent:  Vivid Orange   — warmth, excitement, social energy
/// Support: Deep Purple    — premium, fun, game-specific highlights
///
/// Usage hierarchy:
///   1. Use ColorScheme tokens (context.colorScheme.primary) in widgets
///   2. Use JColors theme extension for Jma3a-specific semantic colors
///   3. AppColors is RAW palette — only use in AppTheme construction
///
/// NEVER use AppColors hex values directly in UI widgets.
abstract final class AppColors {
  // ── Brand: Electric Blue ─────────────────────────────────────────────
  /// Deep navy — primary brand, headers, CTAs in light mode
  static const brandBlueDark = Color(0xFF1B3A5C);

  /// Mid blue — primary in dark mode, links
  static const brandBlueMid = Color(0xFF2D5F9E);

  /// Electric blue — high-energy accents, game highlights
  static const brandBlueElectric = Color(0xFF3B82F6);

  /// Soft blue — containers, backgrounds
  static const brandBlueLight = Color(0xFFDBEAFE);

  // ── Brand: Vivid Orange ──────────────────────────────────────────────
  /// Deep amber — CTA highlights, active states
  static const brandOrangeDark = Color(0xFFEA580C);

  /// Vivid orange — badges, notifications, energy
  static const brandOrangeMid = Color(0xFFF97316);

  /// Soft orange — containers, warm backgrounds
  static const brandOrangeLight = Color(0xFFFFEDD5);

  // ── Brand: Deep Purple ───────────────────────────────────────────────
  /// Deep purple — premium feel, game cards, special states
  static const brandPurpleDark = Color(0xFF4F46E5);

  /// Mid purple — game accents, social badges
  static const brandPurpleMid = Color(0xFF7C3AED);

  /// Soft purple — containers
  static const brandPurpleLight = Color(0xFFEDE9FE);

  // ── Neutrals ─────────────────────────────────────────────────────────
  static const neutral900 = Color(0xFF0F172A);
  static const neutral800 = Color(0xFF1E293B);
  static const neutral700 = Color(0xFF334155);
  static const neutral600 = Color(0xFF475569);
  static const neutral500 = Color(0xFF64748B);
  static const neutral400 = Color(0xFF94A3B8);
  static const neutral300 = Color(0xFFCBD5E1);
  static const neutral200 = Color(0xFFE2E8F0);
  static const neutral100 = Color(0xFFF1F5F9);
  static const neutral50 = Color(0xFFF8FAFC);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);

  // ── Dark surfaces ────────────────────────────────────────────────────
  static const darkBase = Color(0xFF0B1120); // app background
  static const darkSurface = Color(0xFF111827); // cards, sheets
  static const darkElevated = Color(0xFF1A2535); // elevated cards
  static const darkHighest = Color(0xFF1F2E42); // inputs, chips

  // ── Semantic ─────────────────────────────────────────────────────────
  static const successGreen = Color(0xFF16A34A);
  static const successLight = Color(0xFFDCFCE7);
  static const warningAmber = Color(0xFFD97706);
  static const warningLight = Color(0xFFFEF3C7);
  static const errorRed = Color(0xFFDC2626);
  static const errorLight = Color(0xFFFEE2E2);
  static const infoBlue = Color(0xFF2563EB);
  static const infoLight = Color(0xFFDBEAFE);

  // ── Game-specific ─────────────────────────────────────────────────────
  /// Truth cards — blue family
  static const truthColor = Color(0xFF3B82F6);
  static const truthBlue = Color(0xFF3B82F6); // alias
  static const truthBlueDark = Color(0xFF1D4ED8);

  /// Dare cards — red family
  static const dareColor = Color(0xFFEF4444);
  static const dareRed = Color(0xFFEF4444); // alias
  static const dareDark = Color(0xFFB91C1C);

  /// Never Have I Ever — green
  static const nhieGreen = Color(0xFF059669);

  /// Meme Game — yellow/amber
  static const memeYellow = Color(0xFFF59E0B);

  /// Spicy content badge — orange
  static const spicyColor = Color(0xFFEA580C);
  static const spicyOrange = Color(0xFFEA580C); // alias

  /// Room owner crown badge
  static const ownerBadge = Color(0xFFF59E0B);
  static const ownerGold = Color(0xFFF59E0B); // alias

  /// Moderator badge
  static const modBadge = Color(0xFF7C3AED);

  // ── Legacy / backward-compat aliases ─────────────────────────────────
  // These names were used in older screens before the rebrand.
  // Keep them so existing widget code compiles without changes.

  /// Navy blue — maps to brandBlueDark
  static const navyBlue = brandBlueDark;

  /// Navy blue light — maps to brandBlueMid
  static const navyBlueLight = brandBlueMid;

  /// Teal green — maps to nhieGreen
  static const tealGreen = Color(0xFF0A6E56);

  /// Teal green light
  static const tealGreenLight = Color(0xFF1DA57A);

  /// Amber orange light — used for ratings, warm accents
  static const amberOrangeLight = Color(0xFFEA8C1B);

  /// Purple — mid purple alias
  static const purple = brandPurpleMid;
  static const purpleLight = brandPurpleLight;

  /// Text tertiary — muted placeholder / offline state
  static const textTertiaryLight = neutral400;
  static const textTertiaryDark = neutral600;

  // ── Borders ──────────────────────────────────────────────────────────
  static const borderLight = Color(0xFFE2E8F0);
  static const borderSubtle = Color(0xFFF1F5F9);
  static const borderDark = Color(0xFF1F2E42);
  static const borderDarkSub = Color(0xFF172436);
}

// ─── Spacing: strict 4pt grid ────────────────────────────────────────────────
abstract final class AppSpacing {
  static const double px2 = 2;
  static const double px4 = 4; // xs
  static const double px6 = 6;
  static const double px8 = 8; // sm
  static const double px10 = 10;
  static const double px12 = 12; // md-small
  static const double px14 = 14;
  static const double px16 = 16; // md
  static const double px20 = 20;
  static const double px24 = 24; // lg
  static const double px28 = 28;
  static const double px32 = 32; // xl
  static const double px40 = 40;
  static const double px48 = 48; // xxl
  static const double px56 = 56;
  static const double px64 = 64; // xxxl

  // Semantic aliases
  static const double xs = px4;
  static const double sm = px8;
  static const double md = px16;
  static const double lg = px24;
  static const double xl = px32;
  static const double xxl = px48;
  static const double xxxl = px64;

  // Screen edge padding (thumb-friendly horizontal margins)
  static const double screenH = px20; // horizontal screen padding
  static const double screenV = px24; // vertical screen padding
  static const double section = px32; // section spacing
}

// ─── Border radius ────────────────────────────────────────────────────────────
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // Semantic
  static const double button = 12;
  static const double card = 16;
  static const double sheet = 24; // bottom sheets
  static const double dialog = 20;
  static const double input = 12;
  static const double chip = 8;
  static const double badge = 999; // pill
  static const double avatar = 999; // circle

  static BorderRadius get cardRR => BorderRadius.circular(card);
  static BorderRadius get buttonRR => BorderRadius.circular(button);
  static BorderRadius get sheetRR =>
      const BorderRadius.vertical(top: Radius.circular(sheet));
}

// ─── Elevation / shadow system ────────────────────────────────────────────────
/// Jma3a uses colored shadows (brand-tinted) instead of grey.
/// Elevation is expressed as shadow prominence — no actual elevation needed.
abstract final class AppShadows {
  // Subtle — cards at rest
  static List<BoxShadow> card(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: color.withOpacity(0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // Medium — floating buttons, active cards
  static List<BoxShadow> elevated(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.12),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: color.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // Strong — FABs, primary CTAs, game cards
  static List<BoxShadow> prominent(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.25),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: color.withOpacity(0.12),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // Glow — game choice buttons, highlighted states
  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.40),
      blurRadius: 32,
      spreadRadius: -4,
      offset: const Offset(0, 8),
    ),
  ];

  // None — flat cards (when border is used instead)
  static const List<BoxShadow> none = [];
}

// ─── Duration constants ───────────────────────────────────────────────────────
/// All animations use these — no magic numbers in widget code.
abstract final class AppDuration {
  static const instant = Duration(milliseconds: 0);
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 220);
  static const medium = Duration(milliseconds: 350);
  static const slow = Duration(milliseconds: 500);
  static const xslow = Duration(milliseconds: 700);

  // Page transitions
  static const pageEnter = Duration(milliseconds: 280);
  static const pageExit = Duration(milliseconds: 200);

  // Game-specific
  static const cardFlip = Duration(milliseconds: 400);
  static const turnReveal = Duration(milliseconds: 550);
  static const celebration = Duration(milliseconds: 700);
}

// ─── Curve constants ──────────────────────────────────────────────────────────
abstract final class AppCurves {
  // Standard
  static const standard = Curves.easeInOutCubic;
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;

  // Spring-like — for card reveals, game interactions
  static const spring = Curves.easeOutBack;
  static const springIn = Curves.easeInBack;

  // Emphasised — game turn transitions, celebrations
  static const pop = Curves.elasticOut;

  // Decelerate — most commonly used
  static const decel = Curves.decelerate;
}
