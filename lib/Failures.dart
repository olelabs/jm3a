// import 'package:equatable/equatable.dart';

// /// Sealed failure hierarchy.
// ///
// /// Every repository and service method should catch exceptions
// /// and convert them to typed Failures before returning to providers.
// /// Providers expose Failure? — never raw exceptions.
// sealed class Failure extends Equatable {
//   const Failure({required this.message, this.code});

//   final String message;
//   final String? code;

//   @override
//   List<Object?> get props => [message, code];

//   @override
//   String toString() => '${runtimeType}(message: $message, code: $code)';
// }

// /// No internet connection or request timed out.
// final class NetworkFailure extends Failure {
//   const NetworkFailure({
//     super.message = 'Network error. Please check your connection.',
//     super.code,
//   });
// }

// /// JWT missing, expired, or invalid.
// final class AuthFailure extends Failure {
//   const AuthFailure({super.message = 'Authentication required.', super.code});
// }

// /// Resource not found (404-equivalent).
// final class NotFoundFailure extends Failure {
//   const NotFoundFailure({super.message = 'Not found.', super.code});
// }

// /// User lacks permission for this action.
// final class ForbiddenFailure extends Failure {
//   const ForbiddenFailure({
//     super.message = 'You don\'t have permission to do that.',
//     super.code,
//   });
// }

// /// Input validation failed (field-level or request-level).
// final class ValidationFailure extends Failure {
//   const ValidationFailure({
//     required super.message,
//     this.field,
//     super.code = 'validation_error',
//   });

//   final String? field;

//   @override
//   List<Object?> get props => [...super.props, field];
// }

// /// Payment or wallet operation failed.
// final class PaymentFailure extends Failure {
//   const PaymentFailure({required super.message, super.code});
// }

// /// OTP-related failure (expired, invalid, max attempts).
// final class OtpFailure extends Failure {
//   const OtpFailure({required super.message, super.code});
// }

// /// The requested data is unavailable while offline.
// final class OfflineFailure extends Failure {
//   const OfflineFailure({
//     super.message = 'This action requires an internet connection.',
//     super.code = 'offline',
//   });
// }

// /// Unclassified server or unexpected error.
// final class ServerFailure extends Failure {
//   const ServerFailure({
//     super.message = 'An unexpected error occurred. Please try again.',
//     super.code,
//   });
// }

// /// Conflict: resource already exists, duplicate operation, etc.
// final class ConflictFailure extends Failure {
//   const ConflictFailure({required super.message, super.code});
// }

// /// Rate limit exceeded.
// final class RateLimitFailure extends Failure {
//   const RateLimitFailure({
//     super.message = 'Too many requests. Please wait and try again.',
//     this.retryAfterSeconds,
//     super.code = 'rate_limit_exceeded',
//   });

//   final int? retryAfterSeconds;

//   @override
//   List<Object?> get props => [...super.props, retryAfterSeconds];
// }

// /// Join request submitted — waiting for room admin/mod approval.
// final class PendingApprovalFailure extends Failure {
//   const PendingApprovalFailure({
//     super.message = 'Join request sent! Waiting for the host to approve.',
//     super.code = 'pending_approval',
//   });
// }
