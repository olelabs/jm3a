import 'package:flutter/material.dart';

import '../../core/extensions/context_ext.dart';

/// The ONE reusable "developed/owned by MOUJ TECH" ownership mark —
/// every screen listed in the branding requirements renders this instead
/// of hand-rolling its own Text. Text-only by design: an earlier version
/// rendered a cropped MOUJ TECH logo mark beside the text, but that image
/// has been removed from this component — the text alone communicates
/// the ownership fact ("Developed by MOUJ TECH"), and no other screen's
/// use of this widget is affected since it was always the single shared
/// implementation.
///
/// Deliberately subtle: low-opacity, small type, never a button, never
/// intercepts taps — it must never compete with login buttons, game
/// content, navigation, or settings content for attention.
///
/// Positioning is the CALLER's job (this widget is just the mark
/// itself, in-flow) except for safe-area handling, which it always
/// applies internally so no caller has to remember it:
/// * On a scrollable page (Settings, Terms, About, Privacy, auth forms),
///   drop it as the LAST child of the scrollable Column/ListView — it
///   then naturally sits at the end of the content, never fixed over
///   text, and scrolls out of the way of the keyboard like any other
///   form field.
/// * On a non-scrolling composition (Splash), wrap it in `Positioned`/
///   `Align(alignment: Alignment.bottomCenter)` inside the existing
///   `Stack` — do not restructure the composition around it.
enum MoujTechBrandSize { compact, normal }

class MoujTechBrand extends StatelessWidget {
  const MoujTechBrand({
    super.key,
    this.size = MoujTechBrandSize.normal,
    this.showLabel = true,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  });

  final MoujTechBrandSize size;

  /// Whether the "Developed by MOUJ TECH" text renders. Kept true almost
  /// everywhere — text is now this widget's only content, so setting this
  /// false renders nothing.
  final bool showLabel;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (!showLabel) return const SizedBox.shrink();
    final compact = size == MoujTechBrandSize.compact;
    // context.theme's onSurface already adapts to light/dark automatically
    // — no separate dark-mode branch needed.
    final tint = context.colorScheme.onSurface.withValues(alpha: 0.42);

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: padding,
        child: Center(
          child: Text(
            context.l10n.moujTechDevelopedBy,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 10 : 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: tint,
            ),
          ),
        ),
      ),
    );
  }
}
