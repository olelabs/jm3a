import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';

/// Ergonomic extensions on BuildContext.
/// Reduces boilerplate in widget code.
extension ContextExt on BuildContext {
  // ── Localization ───────────────────────────────────────────────────────
  AppLocalizations get l10n => AppLocalizations.of(this);

  // ── Theme ──────────────────────────────────────────────────────────────
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // ── Navigation ─────────────────────────────────────────────────────────
  GoRouter get router => GoRouter.of(this);

  // ── Layout ────────────────────────────────────────────────────────────
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  // ── RTL ───────────────────────────────────────────────────────────────
  bool get isRTL => Directionality.of(this) == TextDirection.rtl;
  TextDirection get textDirection => Directionality.of(this);

  // ── Snackbar helpers ──────────────────────────────────────────────────
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? colorScheme.error
              : colorScheme.inverseSurface,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void showErrorSnackBar(String message) => showSnackBar(message, isError: true);
}

/// Extensions on String for common transformations.
extension StringExt on String {
  bool get isValidEmail {
    return RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
        .hasMatch(this);
  }

  /// Truncate with ellipsis at [maxLength] characters.
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}…';
  }
}
