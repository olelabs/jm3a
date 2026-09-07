import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_ext.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/overlays/branded_status_view.dart';

class TodLoadingScreen extends StatelessWidget {
  const TodLoadingScreen({super.key, this.subtitle});

  /// Overrides the default "loading the game" copy — used for the
  /// game-session ready barrier's "waiting for other players" phase,
  /// which is a distinct wait from the initial load but visually
  /// identical, so it reuses this same screen rather than a new one.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    // UI redesign only — same copy/override semantics as before.
    return BrandedStatusView(
      emoji: '🎯',
      title: context.l10n.gameNameTruthOrDare,
      subtitle: subtitle ?? context.l10n.todLoadingGame,
      accent: AppColors.brandPurpleMid,
    );
  }
}
