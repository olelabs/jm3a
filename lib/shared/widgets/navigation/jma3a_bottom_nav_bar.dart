import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

/// One tab of [Jma3aBottomNavBar]. Carries both a Material icon pair (used
/// on Android and iOS <26 — this app renders Cupertino icons only as an
/// icon *style* choice, never as a native Cupertino navigation widget) and
/// a Cupertino icon pair (closest bundled equivalent to the platform's own
/// SF Symbols, used only on iOS).
class Jma3aNavDestination {
  const Jma3aNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.cupertinoIcon,
    required this.cupertinoSelectedIcon,
    required this.label,
    this.badgeCount = 0,
    this.selectedIconOverride,
  });

  final IconData icon;
  final IconData selectedIcon;
  final IconData cupertinoIcon;
  final IconData cupertinoSelectedIcon;
  final String label;
  final int badgeCount;

  /// Escape hatch for a fully custom selected-state icon (e.g. Profile's
  /// premium gradient treatment), still receiving the platform choice so
  /// the override itself can stay platform-adaptive too. When present, it
  /// replaces the default icon+badge composition for the SELECTED state
  /// only — the unselected icon still comes from [icon]/[cupertinoIcon].
  final Widget Function(bool isIOS)? selectedIconOverride;
}

/// Modern WhatsApp/iOS-26-Liquid-Glass-inspired floating bottom navigation.
///
/// IMPORTANT — why this does NOT use Material 3 [NavigationBar]: that
/// widget always paints its own opaque `Material` surface (this app's
/// theme sets `navigationBarTheme.backgroundColor: colorScheme.surface`),
/// and that opaque paint happens *inside* any blur/translucency wrapped
/// around it — it simply covers the glass effect up, which is what made
/// an earlier version of this widget look like a solid bottom sheet
/// instead of a floating glass control. This widget instead renders the
/// destinations itself (still via `Material(type: transparency)` +
/// `InkWell` for correct ripple/semantics/touch targets) inside a
/// `BackdropFilter`, so the blur and low-opacity tint are the ONLY paint —
/// there is no opaque layer anywhere in the stack, and app content is
/// meant to show through around and behind the floating pill.
class Jma3aBottomNavBar extends StatelessWidget {
  const Jma3aBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<Jma3aNavDestination> destinations;

  /// Height of the row of destinations itself, excluding the safe-area
  /// clearance and gap added below it. Shared with [overlayInset] so the
  /// two never drift apart.
  static const double barHeight = 60;

  /// Visual gap kept between the bar's bottom edge and the safe area
  /// below it (home indicator / gesture bar / physical bottom edge).
  static const double bottomGap = 10;

  /// Visual gap kept between a screen's own FloatingActionButton and the
  /// navbar's top edge — see [fabLocation].
  static const double fabGap = 45;

  /// Total vertical footprint this floating control occupies above the
  /// physical bottom edge of the screen. Since the bar is a true floating
  /// overlay (see [Jma3aBottomNavBar]'s own doc comment and HomeShellScreen's
  /// `extendBody: true`), nothing reserves this space automatically —
  /// callers that host it use this to give their own scrollable content a
  /// trailing inset so the last item ends up reachable just above the
  /// glass control instead of underneath it.
  ///
  /// Deliberately reads `MediaQuery.viewPaddingOf` (the fixed physical
  /// safe-area inset), NOT `MediaQuery.paddingOf`: `Scaffold(extendBody:
  /// true)` — which HomeShellScreen uses so this bar's own translucency
  /// works — wraps its body in a MediaQuery whose `padding.bottom` is
  /// `max(original safe area, this bar's OWN measured height)`. Since
  /// this bar's measured height already roughly equals the very number
  /// being computed here, reading `padding` at ANY point inside that body
  /// would double the whole footprint back into itself. `viewPadding` is
  /// never touched by that mechanism, so it stays the true, single, raw
  /// safe-area value no matter where in the tree it's read from.
  static double overlayInset(BuildContext context) =>
      barHeight + bottomGap + MediaQuery.viewPaddingOf(context).bottom;

  /// FloatingActionButtonLocation for a screen that floats a FAB above
  /// this navbar: positions it exactly [fabGap] above the bar's own top
  /// edge, reusing [FloatingActionButtonLocation.endFloat] for the
  /// horizontal placement (unchanged — safe-area/RTL-aware end margin)
  /// and overriding only the vertical one.
  ///
  /// Scaffold's own default FAB locations aren't used for this because
  /// they always add their own fixed `kFloatingActionButtonMargin` (16)
  /// on top of whatever safe-area signal they're given, which cannot by
  /// itself produce the tight ~[fabGap] gap this app wants above a
  /// floating bar — this computes the FAB's exact target offset directly
  /// from the bar's own known geometry instead.
  static FloatingActionButtonLocation fabLocation(BuildContext context) =>
      _AboveNavBarFabLocation(overlayInset(context) + fabGap);

  static bool get _isIOS {
    try {
      return Platform.isIOS;
    } catch (_) {
      // Platform.isIOS throws on web/test environments without dart:io
      // support; neither Liquid Glass nor iOS haptics apply there.
      return false;
    }
  }

  /// `Platform.operatingSystemVersion` returns a free-form string (e.g.
  /// "Version 17.4 (Build 21E5254a)" on iOS) rather than a structured
  /// version — there is no dedicated package for this already in the
  /// project (see inspection report: adding one purely for a single
  /// major-version comparison was judged unnecessary). Parsing is
  /// deliberately conservative: any failure means "not 26+", which is the
  /// safe default (plain fallback glass) rather than guessing.
  static bool get _isIOS26OrAbove {
    if (!_isIOS) return false;
    try {
      final match = RegExp(r'\d+').firstMatch(Platform.operatingSystemVersion);
      if (match == null) return false;
      return int.parse(match.group(0)!) >= 26;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isIOS = _isIOS;
    final useGlass = _isIOS26OrAbove;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final radius = BorderRadius.circular(AppRadius.xxl);

    // The outer shell carries NO color fill at all — a tint here (even a
    // low-alpha one) reads as a visible pill/rectangle behind the bar,
    // which is exactly the "filled panel" look this must not have. The
    // backdrop blur alone (no color) is what makes this still read as a
    // floating glass control rather than an invisible hit-test region;
    // content stays visible through it. iOS 26+ still gets a stronger
    // blur than the cross-platform fallback — that's the only remaining
    // difference between the two tiers.
    const tintAlpha = 0.0;
    final blurSigma = useGlass ? 30.0 : 16.0;
    final rimAlpha = useGlass ? 0.35 : 0.6;

    final content = Material(
      type: MaterialType.transparency,
      child: SizedBox(
        height: barHeight,
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++)
              _NavItem(
                destination: destinations[i],
                selected: i == selectedIndex,
                isIOS: isIOS,
                reduceMotion: reduceMotion,
                onTap: () {
                  if (isIOS) HapticFeedback.selectionClick();
                  onDestinationSelected(i);
                },
              ),
          ],
        ),
      ),
    );

    // WhatsApp-style horizontal swipe across the bar itself changes tabs
    // through the SAME callback a tap uses — decided once at drag end
    // (not continuously during the drag) so this widget never rebuilds
    // mid-gesture, which would otherwise reset `dragTotal` and lose the
    // accumulated distance. `HitTestBehavior.translucent` lets this still
    // recognize the drag over the gaps between items AND over the items
    // themselves without stealing their taps (a plain tap never travels
    // far enough to be claimed by the drag recognizer).
    double dragTotal = 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.paddingOf(context).bottom + bottomGap,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) {
          dragTotal += details.primaryDelta ?? 0;
        },
        onHorizontalDragEnd: (details) {
          const threshold = 40.0;
          final delta = isRtl ? -dragTotal : dragTotal;
          dragTotal = 0;
          if (delta.abs() < threshold || destinations.length < 2) return;
          final direction = delta < 0 ? 1 : -1;
          final newIndex = (selectedIndex + direction).clamp(
            0,
            destinations.length - 1,
          );
          if (newIndex != selectedIndex) {
            if (isIOS) HapticFeedback.selectionClick();
            onDestinationSelected(newIndex);
          }
        },
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: tintAlpha),
                borderRadius: radius,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: rimAlpha,
                  ),
                  width: useGlass ? 0.8 : 1,
                ),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.isIOS,
    required this.reduceMotion,
    required this.onTap,
  });

  final Jma3aNavDestination destination;
  final bool selected;
  final bool isIOS;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    final iconWidget = IconTheme.merge(
      data: IconThemeData(color: color, size: 22),
      child: _buildIcon(
        destination,
        selected: selected,
        isIOS: isIOS,
        reduceMotion: reduceMotion,
      ),
    );

    // The glass surface belongs to the NAVBAR CONTAINER, not to individual
    // items — an unselected item is just its bare icon, with no
    // Container/decoration/box of its own at all (not even a transparent
    // one). Only the selected tab gets the compact pill treatment.
    final iconArea = selected
        ? AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(999),
            ),
            child: iconWidget,
          )
        : iconWidget;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: destination.label,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          // Individual items must stay visually transparent — Material's
          // default InkWell splash/highlight/hover colors would otherwise
          // paint a tinted rounded-rect across this item's FULL cell on
          // every tap (and, on desktop/web, on hover too), which is
          // exactly the "each item has its own glass background" look
          // this must not have. The deliberate selected-state pill above
          // remains the only per-item visual treatment.
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconArea,
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  style: (theme.textTheme.labelSmall ?? const TextStyle())
                      .copyWith(
                        color: color,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(
    Jma3aNavDestination d, {
    required bool selected,
    required bool isIOS,
    required bool reduceMotion,
  }) {
    if (selected && d.selectedIconOverride != null) {
      return d.selectedIconOverride!(isIOS);
    }

    final iconData = isIOS
        ? (selected ? d.cupertinoSelectedIcon : d.cupertinoIcon)
        : (selected ? d.selectedIcon : d.icon);
    Widget icon = Icon(iconData);

    if (d.badgeCount > 0) {
      icon = Badge(label: Text('${d.badgeCount}'), child: icon);
    }

    if (!selected || reduceMotion) return icon;

    // A fresh TweenAnimationBuilder mounts (and so animates from `begin`)
    // every time this destination becomes the selected one, giving the
    // "pop" purely from a stock implicit-animation widget, no
    // AnimationController needed.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.82, end: 1.0),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: icon,
    );
  }
}

class _AboveNavBarFabLocation extends FloatingActionButtonLocation {
  const _AboveNavBarFabLocation(this._bottomClearance);

  /// Distance from the scaffold's own bottom edge to the FAB's bottom
  /// edge — i.e. `Jma3aBottomNavBar.overlayInset(context) + fabGap`.
  final double _bottomClearance;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Horizontal placement is untouched — same end-aligned, safe-area/RTL
    // aware margin `endFloat` already computes correctly.
    final dx = FloatingActionButtonLocation.endFloat
        .getOffset(scaffoldGeometry)
        .dx;
    final fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    final dy =
        scaffoldGeometry.scaffoldSize.height - _bottomClearance - fabHeight;
    return Offset(dx, dy);
  }
}
