import 'package:logger/logger.dart';

import '../config/app_config.dart';

/// Structured logger for Jma3a.
///
/// In development: colorized console output via logger package.
/// In production: add Sentry/Crashlytics integration here.
///
/// Sensitive values (tokens, OTPs, passwords) must never be logged.
abstract final class AppLogger {
  static final _logger = Logger(
    level: _logLevel,
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    output: ConsoleOutput(),
  );

  static Level get _logLevel =>
      AppConfig.isDevelopment ? Level.debug : Level.warning;

  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(String message) {
    _logger.i(message);
  }

  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    // TODO: forward to Sentry/Crashlytics in production
    // if (AppConfig.isProduction) {
    //   Sentry.captureException(error, stackTrace: stackTrace);
    // }
  }

  static void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
