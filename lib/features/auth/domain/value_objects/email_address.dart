import 'package:equatable/equatable.dart';

/// Validated email address value object.
/// Construct with [EmailAddress.parse] — throws [FormatException] if invalid.
/// Stores the normalised (lowercase, trimmed) form.
class EmailAddress extends Equatable {
  const EmailAddress._(this.value);

  /// Normalised email value.
  final String value;

  /// Canonical domain part (lowercased).
  String get domain => value.split('@').last;

  /// Local part (before @).
  String get localPart => value.split('@').first;

  static final _regex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  /// Parse and validate an email string.
  /// Returns an [EmailAddress] or null if invalid.
  static EmailAddress? tryParse(String? raw) {
    final normalised = raw?.trim().toLowerCase() ?? '';
    if (normalised.isEmpty) return null;
    if (normalised.length > 254) return null;
    if (!_regex.hasMatch(normalised)) return null;
    return EmailAddress._(normalised);
  }

  @override
  String toString() => value;

  @override
  List<Object?> get props => [value];
}
