import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Validated, typed access to all environment variables.
///
/// Call [validate] at startup — the app will throw immediately
/// if any required variable is missing or malformed.
/// This is intentional: better to crash loudly than to run misconfigured.
class AppConfig {
  AppConfig._();

  // ── Supabase ──────────────────────────────────────────────────────────
  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');

  // ── Node.js API ───────────────────────────────────────────────────────
  static String get apiBaseUrl => _require('API_BASE_URL');
  static Duration get apiTimeout => Duration(
    seconds: int.tryParse(dotenv.env['API_TIMEOUT_SECONDS'] ?? '30') ?? 30,
  );

  // ── OneSignal ─────────────────────────────────────────────────────────
  static String get oneSignalAppId => _require('ONESIGNAL_APP_ID');

  // ── Storage ───────────────────────────────────────────────────────────
  static String get wasabiPublicUrl => _require('WASABI_PUBLIC_URL');

  // ── App environment ───────────────────────────────────────────────────
  static AppEnvironment get environment {
    return switch (dotenv.env['APP_ENV'] ?? 'development') {
      'production' => AppEnvironment.production,
      'staging' => AppEnvironment.staging,
      _ => AppEnvironment.development,
    };
  }

  static bool get isProduction => environment == AppEnvironment.production;
  static bool get isDevelopment => environment == AppEnvironment.development;

  // ── Validation ────────────────────────────────────────────────────────
  static void validate() {
    const required = [
      'SUPABASE_URL',
      'SUPABASE_ANON_KEY',
      'API_BASE_URL',
      'ONESIGNAL_APP_ID',
      'WASABI_PUBLIC_URL',
    ];

    final missing = required.where((k) => dotenv.env[k]?.isEmpty ?? true).toList();
    if (missing.isNotEmpty) {
      throw AppConfigException(
        'Missing required environment variables: ${missing.join(', ')}\n'
        'Check your .env file against .env.example',
      );
    }

    // URL format validation
    if (Uri.tryParse(supabaseUrl)?.hasScheme != true) {
      throw AppConfigException('SUPABASE_URL must be a valid URL');
    }
    if (Uri.tryParse(apiBaseUrl)?.hasScheme != true) {
      throw AppConfigException('API_BASE_URL must be a valid URL');
    }
  }

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw AppConfigException('Required environment variable "$key" is not set');
    }
    return value;
  }
}

enum AppEnvironment { development, staging, production }

class AppConfigException implements Exception {
  AppConfigException(this.message);
  final String message;

  @override
  String toString() => 'AppConfigException: $message';
}
