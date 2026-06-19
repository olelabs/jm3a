import '../errors/error_handler.dart';
import '../errors/failures.dart';
import '../services/connectivity_service.dart';
import '../utils/app_logger.dart';

/// Abstract base class for all repositories.
///
/// Repositories implement the [IRepository] interface and extend this
/// base to get connectivity checking and error handling utilities.
///
/// Pattern:
/// ```dart
/// class PackRepository extends BaseRepository implements IPackRepository {
///   Future<List<PackEntity>> getPacks() => guardedCall(
///     operation: () async {
///       final rows = await _remote.fetchPacks();
///       return rows.map(PackMapper.toEntity).toList();
///     },
///     requiresNetwork: true,
///   );
/// }
/// ```
abstract class BaseRepository {
  BaseRepository({ConnectivityService? connectivityService})
      : _connectivity = connectivityService ?? ConnectivityService.instance;

  final ConnectivityService _connectivity;

  /// Wraps a repository operation with:
  /// 1. Optional connectivity check
  /// 2. Exception → Failure conversion
  /// 3. Structured logging
  Future<T> guardedCall<T>({
    required Future<T> Function() operation,
    bool requiresNetwork = true,
    String? operationName,
  }) async {
    if (requiresNetwork && !_connectivity.isOnline) {
      throw const OfflineFailure();
    }

    try {
      return await operation();
    } catch (e, st) {
      final name = operationName ?? runtimeType.toString();
      AppLogger.error('Repository error in $name', error: e, stackTrace: st);
      throw ErrorHandler.handle(e, st);
    }
  }

  /// Like [guardedCall] but returns null instead of throwing on failure.
  /// Use for non-critical operations where fallback to cache is acceptable.
  Future<T?> softCall<T>({
    required Future<T> Function() operation,
    bool requiresNetwork = true,
    String? operationName,
  }) async {
    try {
      return await guardedCall(
        operation: operation,
        requiresNetwork: requiresNetwork,
        operationName: operationName,
      );
    } on Failure {
      return null;
    }
  }
}
