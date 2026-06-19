import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/app_logger.dart';

/// Secure key-value storage for sensitive data.
///
/// Uses Keychain on iOS, Keystore on Android.
/// Used for: Supabase tokens, OTP email pending state.
/// Never store passwords, card numbers, or government IDs here.
class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService _instance = SecureStorageService._();
  static SecureStorageService get instance => _instance;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
    AppLogger.info('SecureStorage cleared');
  }

  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key: key);
  }
}

/// Well-known storage keys — never hardcode strings in feature code.
abstract final class SecureKeys {
  static const supabaseAccessToken  = 'supabase.access_token';
  static const supabaseRefreshToken = 'supabase.refresh_token';
  static const pendingOtpEmail      = 'auth.pending_otp_email';
}
