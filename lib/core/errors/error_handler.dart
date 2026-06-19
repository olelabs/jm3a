import 'dart:io';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_logger.dart';
import 'failures.dart';

/// Maps any exception type into a typed [Failure].
///
/// Use in repository catch blocks:
/// ```dart
/// } catch (e, st) {
///   throw ErrorHandler.handle(e, st);
/// }
/// ```
abstract final class ErrorHandler {
  static Failure handle(Object error, [StackTrace? stackTrace]) {
    AppLogger.error('ErrorHandler.handle', error: error, stackTrace: stackTrace);

    return switch (error) {
      // Already a Failure — pass through
      final Failure f => f,

      // Supabase auth errors
      AuthException e => _handleAuthException(e),

      // Supabase DB / RLS errors
      PostgrestException e => _handlePostgrestException(e),

      // Supabase storage errors
      StorageException e => StorageException == e
          ? const ServerFailure(message: 'Storage operation failed.')
          : ServerFailure(message: e.message),

      // Dio / Node.js API errors
      DioException e => _handleDioException(e),

      // Network
      SocketException _ => const NetworkFailure(),
      HandshakeException _ => const NetworkFailure(
          message: 'Secure connection failed.'),

      // Fallback
      _ => ServerFailure(message: error.toString()),
    };
  }

  // ── Supabase Auth ────────────────────────────────────────────────────
  static Failure _handleAuthException(AuthException e) {
    return switch (e.statusCode) {
      '400' => AuthFailure(message: e.message, code: 'bad_request'),
      '401' => const AuthFailure(),
      '422' => OtpFailure(message: e.message, code: 'otp_error'),
      '429' => const RateLimitFailure(),
      _ => AuthFailure(message: e.message),
    };
  }

  // ── Supabase Postgrest ────────────────────────────────────────────────
  static Failure _handlePostgrestException(PostgrestException e) {
    // Postgres error codes: https://www.postgresql.org/docs/current/errcodes-appendix.html
    return switch (e.code) {
      'PGRST116' => const NotFoundFailure(),   // exactly 0 rows
      '42501'    => const ForbiddenFailure(),  // RLS violation
      '23505'    => ConflictFailure(message: e.message, code: 'duplicate'),
      '23503'    => ValidationFailure(message: 'Referenced record not found.', code: e.code),
      _          => ServerFailure(message: e.message, code: e.code),
    };
  }

  // ── Dio / Node.js API ────────────────────────────────────────────────
  static Failure _handleDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NetworkFailure(message: 'Request timed out.');
    }

    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }

    final statusCode = e.response?.statusCode;
    final body = e.response?.data;

    // Try to extract structured error from Node.js response shape:
    // { "success": false, "error": { "code": "...", "message": "..." } }
    final errorBody = body is Map ? (body['error'] as Map?) : null;
    final code = errorBody?['code'] as String?;
    final message = errorBody?['message'] as String?;

    return switch (statusCode) {
      400 => ValidationFailure(
          message: message ?? 'Invalid request.',
          code: code,
        ),
      401 => const AuthFailure(),
      403 => const ForbiddenFailure(),
      404 => NotFoundFailure(message: message ?? 'Not found.', code: code),
      409 => ConflictFailure(message: message ?? 'Conflict.', code: code),
      422 => switch (code) {
          'otp_invalid'       => OtpFailure(message: message ?? 'Invalid OTP.', code: code),
          'otp_expired'       => OtpFailure(message: message ?? 'OTP expired.', code: code),
          'otp_max_attempts'  => OtpFailure(message: message ?? 'Too many attempts.', code: code),
          'insufficient_funds' => PaymentFailure(message: message ?? 'Insufficient funds.', code: code),
          _                   => ValidationFailure(message: message ?? 'Validation failed.', code: code),
        },
      429 => RateLimitFailure(
          message: message ?? 'Too many requests.',
          retryAfterSeconds: errorBody?['retry_after'] as int?,
          code: code,
        ),
      _ => ServerFailure(
          message: message ?? 'Server error.',
          code: code ?? statusCode?.toString(),
        ),
    };
  }
}
