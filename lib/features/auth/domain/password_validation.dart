import '../../../core/l10n/generated/app_localizations.dart';

/// Shared password-format validation — used by signup, first-time
/// password setup, password recovery, and the Settings "Update Password"
/// flow, so the policy can never silently drift between them. Mirrors
/// the backend's own policy exactly (src/middleware/validate.js's
/// passwordValidator/newPasswordValidator): 8-72 characters, at least
/// one letter and one digit.
String? validatePasswordFormat(String? value, AppLocalizations l10n) {
  final v = value ?? '';
  if (v.isEmpty) return l10n.authPasswordRequired;
  if (v.length < 8) return l10n.authPasswordTooShort;
  if (v.length > 72) return l10n.authPasswordTooLong;
  if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
    return l10n.authPasswordNeedsLetterAndDigit;
  }
  return null;
}

/// Confirmation-field validator — shared for the same reason.
String? validatePasswordConfirmation(
  String? value,
  String password,
  AppLocalizations l10n,
) {
  if (value != password) return l10n.authPasswordMismatch;
  return null;
}
