import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ═══════════════════════════════════════════════════════════════
/// JThemeExtension — Jma3a-specific semantic colors
/// ═══════════════════════════════════════════════════════════════
///
/// Accessed via: Theme.of(context).extension<JThemeExtension>()!
/// Or via context extension: context.jColors
///
/// These colors don't belong in Material ColorScheme but are needed
/// for game-specific states, social indicators, and brand moments.
@immutable
class JThemeExtension extends ThemeExtension<JThemeExtension> {
  const JThemeExtension({
    required this.truthCardBg,
    required this.truthCardFg,
    required this.dareCardBg,
    required this.dareCardFg,
    required this.nhieCardBg,
    required this.nhieCardFg,
    required this.memeCardBg,
    required this.memeCardFg,
    required this.spicyBadgeBg,
    required this.spicyBadgeFg,
    required this.ownerBadge,
    required this.modBadge,
    required this.onlineDot,
    required this.inGameDot,
    required this.offlineDot,
    required this.gameProgressActive,
    required this.gameProgressBg,
    required this.walletCredit,
    required this.walletDebit,
    required this.packCardGradientStart,
    required this.packCardGradientEnd,
    required this.toastBg,
    required this.toastFg,
    required this.frozenOverlay,
    required this.reactionPill,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  // ── Game cards ─────────────────────────────────────────────────────────
  final Color truthCardBg;
  final Color truthCardFg;
  final Color dareCardBg;
  final Color dareCardFg;
  final Color nhieCardBg;
  final Color nhieCardFg;
  final Color memeCardBg;
  final Color memeCardFg;
  final Color spicyBadgeBg;
  final Color spicyBadgeFg;

  // ── Social badges ──────────────────────────────────────────────────────
  final Color ownerBadge;
  final Color modBadge;

  // ── Presence indicators ────────────────────────────────────────────────
  final Color onlineDot;
  final Color inGameDot;
  final Color offlineDot;

  // ── Game progress bar ──────────────────────────────────────────────────
  final Color gameProgressActive;
  final Color gameProgressBg;

  // ── Wallet ─────────────────────────────────────────────────────────────
  final Color walletCredit;
  final Color walletDebit;

  // ── Pack cards ─────────────────────────────────────────────────────────
  final Color packCardGradientStart;
  final Color packCardGradientEnd;

  // ── Toasts ─────────────────────────────────────────────────────────────
  final Color toastBg;
  final Color toastFg;

  // ── States ─────────────────────────────────────────────────────────────
  final Color frozenOverlay;
  final Color reactionPill;

  // ── Shimmer ────────────────────────────────────────────────────────────
  final Color shimmerBase;
  final Color shimmerHighlight;

  // ── Light preset ──────────────────────────────────────────────────────
  static const light = JThemeExtension(
    truthCardBg:          Color(0xFF1D4ED8),
    truthCardFg:          AppColors.white,
    dareCardBg:           Color(0xFFB91C1C),
    dareCardFg:           AppColors.white,
    nhieCardBg:           Color(0xFF047857),
    nhieCardFg:           AppColors.white,
    memeCardBg:           Color(0xFF92400E),
    memeCardFg:           AppColors.white,
    spicyBadgeBg:         Color(0xFFEA580C),
    spicyBadgeFg:         AppColors.white,
    ownerBadge:           Color(0xFFF59E0B),
    modBadge:             Color(0xFF7C3AED),
    onlineDot:            Color(0xFF16A34A),
    inGameDot:            Color(0xFFF97316),
    offlineDot:           Color(0xFF94A3B8),
    gameProgressActive:   Color(0xFF3B82F6),
    gameProgressBg:       Color(0xFFE2E8F0),
    walletCredit:         Color(0xFF16A34A),
    walletDebit:          Color(0xFFDC2626),
    packCardGradientStart: Color(0xFF1B3A5C),
    packCardGradientEnd:   Color(0xFF2D5F9E),
    toastBg:              Color(0xFF1E293B),
    toastFg:              AppColors.white,
    frozenOverlay:        Color(0x1A94A3B8),
    reactionPill:         Color(0xFFEDE9FE),
    shimmerBase:          Color(0xFFE2E8F0),
    shimmerHighlight:     Color(0xFFF1F5F9),
  );

  // ── Dark preset ────────────────────────────────────────────────────────
  static const dark = JThemeExtension(
    truthCardBg:          Color(0xFF1E40AF),
    truthCardFg:          AppColors.white,
    dareCardBg:           Color(0xFF991B1B),
    dareCardFg:           AppColors.white,
    nhieCardBg:           Color(0xFF065F46),
    nhieCardFg:           AppColors.white,
    memeCardBg:           Color(0xFF78350F),
    memeCardFg:           AppColors.white,
    spicyBadgeBg:         Color(0xFFC2410C),
    spicyBadgeFg:         AppColors.white,
    ownerBadge:           Color(0xFFD97706),
    modBadge:             Color(0xFF6D28D9),
    onlineDot:            Color(0xFF22C55E),
    inGameDot:            Color(0xFFFB923C),
    offlineDot:           Color(0xFF475569),
    gameProgressActive:   Color(0xFF60A5FA),
    gameProgressBg:       Color(0xFF1F2E42),
    walletCredit:         Color(0xFF22C55E),
    walletDebit:          Color(0xFFF87171),
    packCardGradientStart: Color(0xFF0F1923),
    packCardGradientEnd:   Color(0xFF1A2D4A),
    toastBg:              Color(0xFF1A2535),
    toastFg:              Color(0xFFF1F5F9),
    frozenOverlay:        Color(0x1A64748B),
    reactionPill:         Color(0xFF2D1F4E),
    shimmerBase:          Color(0xFF1E2D3D),
    shimmerHighlight:     Color(0xFF263748),
  );

  @override
  JThemeExtension copyWith({
    Color? truthCardBg, Color? truthCardFg,
    Color? dareCardBg, Color? dareCardFg,
    Color? nhieCardBg, Color? nhieCardFg,
    Color? memeCardBg, Color? memeCardFg,
    // ... all fields
  }) =>
      JThemeExtension(
        truthCardBg: truthCardBg ?? this.truthCardBg,
        truthCardFg: truthCardFg ?? this.truthCardFg,
        dareCardBg:  dareCardBg  ?? this.dareCardBg,
        dareCardFg:  dareCardFg  ?? this.dareCardFg,
        nhieCardBg:  nhieCardBg  ?? this.nhieCardBg,
        nhieCardFg:  nhieCardFg  ?? this.nhieCardFg,
        memeCardBg:  memeCardBg  ?? this.memeCardBg,
        memeCardFg:  memeCardFg  ?? this.memeCardFg,
        spicyBadgeBg:  spicyBadgeBg  ?? this.spicyBadgeBg,
        spicyBadgeFg:  spicyBadgeFg  ?? this.spicyBadgeFg,
        ownerBadge:    ownerBadge    ?? this.ownerBadge,
        modBadge:      modBadge      ?? this.modBadge,
        onlineDot:     onlineDot     ?? this.onlineDot,
        inGameDot:     inGameDot     ?? this.inGameDot,
        offlineDot:    offlineDot    ?? this.offlineDot,
        gameProgressActive: gameProgressActive ?? this.gameProgressActive,
        gameProgressBg:     gameProgressBg     ?? this.gameProgressBg,
        walletCredit:  walletCredit  ?? this.walletCredit,
        walletDebit:   walletDebit   ?? this.walletDebit,
        packCardGradientStart: packCardGradientStart ?? this.packCardGradientStart,
        packCardGradientEnd:   packCardGradientEnd   ?? this.packCardGradientEnd,
        toastBg:       toastBg       ?? this.toastBg,
        toastFg:       toastFg       ?? this.toastFg,
        frozenOverlay: frozenOverlay ?? this.frozenOverlay,
        reactionPill:  reactionPill  ?? this.reactionPill,
        shimmerBase:       shimmerBase      ?? this.shimmerBase,
        shimmerHighlight:  shimmerHighlight ?? this.shimmerHighlight,
      );

  @override
  JThemeExtension lerp(JThemeExtension? other, double t) {
    if (other == null) return this;
    return JThemeExtension(
      truthCardBg:  Color.lerp(truthCardBg,  other.truthCardBg,  t)!,
      truthCardFg:  Color.lerp(truthCardFg,  other.truthCardFg,  t)!,
      dareCardBg:   Color.lerp(dareCardBg,   other.dareCardBg,   t)!,
      dareCardFg:   Color.lerp(dareCardFg,   other.dareCardFg,   t)!,
      nhieCardBg:   Color.lerp(nhieCardBg,   other.nhieCardBg,   t)!,
      nhieCardFg:   Color.lerp(nhieCardFg,   other.nhieCardFg,   t)!,
      memeCardBg:   Color.lerp(memeCardBg,   other.memeCardBg,   t)!,
      memeCardFg:   Color.lerp(memeCardFg,   other.memeCardFg,   t)!,
      spicyBadgeBg: Color.lerp(spicyBadgeBg, other.spicyBadgeBg, t)!,
      spicyBadgeFg: Color.lerp(spicyBadgeFg, other.spicyBadgeFg, t)!,
      ownerBadge:   Color.lerp(ownerBadge,   other.ownerBadge,   t)!,
      modBadge:     Color.lerp(modBadge,     other.modBadge,     t)!,
      onlineDot:    Color.lerp(onlineDot,    other.onlineDot,    t)!,
      inGameDot:    Color.lerp(inGameDot,    other.inGameDot,    t)!,
      offlineDot:   Color.lerp(offlineDot,   other.offlineDot,   t)!,
      gameProgressActive: Color.lerp(gameProgressActive, other.gameProgressActive, t)!,
      gameProgressBg:     Color.lerp(gameProgressBg,     other.gameProgressBg,     t)!,
      walletCredit:  Color.lerp(walletCredit,  other.walletCredit,  t)!,
      walletDebit:   Color.lerp(walletDebit,   other.walletDebit,   t)!,
      packCardGradientStart: Color.lerp(packCardGradientStart, other.packCardGradientStart, t)!,
      packCardGradientEnd:   Color.lerp(packCardGradientEnd,   other.packCardGradientEnd,   t)!,
      toastBg:       Color.lerp(toastBg,       other.toastBg,       t)!,
      toastFg:       Color.lerp(toastFg,       other.toastFg,       t)!,
      frozenOverlay: Color.lerp(frozenOverlay, other.frozenOverlay, t)!,
      reactionPill:  Color.lerp(reactionPill,  other.reactionPill,  t)!,
      shimmerBase:      Color.lerp(shimmerBase,      other.shimmerBase,      t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
    );
  }
}

/// Convenience accessor on BuildContext
extension JThemeExt on BuildContext {
  JThemeExtension get jColors =>
      Theme.of(this).extension<JThemeExtension>()!;
}
