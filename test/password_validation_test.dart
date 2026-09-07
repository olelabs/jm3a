// Shared password-format validation, used by signup, first-time setup,
// recovery, and Settings' Update Password flow. Mirrors the backend's
// own policy (validate.js's passwordValidator/newPasswordValidator)
// exactly — 8-72 characters, at least one letter and one digit.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jma3a/core/l10n/generated/app_localizations_en.dart';
import 'package:jma3a/features/auth/domain/password_validation.dart';

void main() {
  final l10n = AppLocalizationsEn();

  setUpAll(() {
    dotenv.testLoad(fileInput: '');
  });

  group('validatePasswordFormat', () {
    test('rejects empty', () {
      expect(validatePasswordFormat('', l10n), isNotNull);
    });

    test('rejects too short', () {
      expect(validatePasswordFormat('ab1', l10n), isNotNull);
    });

    test('rejects too long (>72 chars)', () {
      expect(validatePasswordFormat('a1' * 40, l10n), isNotNull);
    });

    test('rejects letters only', () {
      expect(validatePasswordFormat('onlylettersnodigits', l10n), isNotNull);
    });

    test('rejects digits only', () {
      expect(validatePasswordFormat('12345678', l10n), isNotNull);
    });

    test('accepts a valid password', () {
      expect(validatePasswordFormat('correcthorse1', l10n), isNull);
    });
  });

  group('validatePasswordConfirmation', () {
    test('rejects a mismatch', () {
      expect(
        validatePasswordConfirmation('different1', 'correcthorse1', l10n),
        isNotNull,
      );
    });

    test('accepts a match', () {
      expect(
        validatePasswordConfirmation('correcthorse1', 'correcthorse1', l10n),
        isNull,
      );
    });
  });
}
