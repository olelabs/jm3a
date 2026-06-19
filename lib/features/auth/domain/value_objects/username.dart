import 'package:equatable/equatable.dart';

/// Validated username value object.
/// Rules: 3–30 chars, lowercase letters / numbers / underscores.
class Username extends Equatable {
  const Username._(this.value);

  final String value;

  static final _regex = RegExp(r'^[a-z0-9_]{3,30}$');

  static Username? tryParse(String? raw) {
    final normalised = raw?.trim().toLowerCase() ?? '';
    if (!_regex.hasMatch(normalised)) return null;
    return Username._(normalised);
  }

  static String? validate(String? raw) {
    final normalised = raw?.trim().toLowerCase() ?? '';
    if (normalised.isEmpty) return 'Username is required.';
    if (normalised.length < 3) return 'At least 3 characters.';
    if (normalised.length > 30) return 'Maximum 30 characters.';
    if (!_regex.hasMatch(normalised)) {
      return 'Only lowercase letters, numbers, and underscores.';
    }
    return null;
  }

  @override
  String toString() => value;

  @override
  List<Object?> get props => [value];
}
