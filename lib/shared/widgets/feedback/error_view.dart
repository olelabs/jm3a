import 'package:flutter/material.dart';

import '../../../core/errors/failures.dart';
import '../../../core/extensions/context_ext.dart';
import '../buttons/j_button.dart';

/// Generic error state widget.
/// Used in screens/lists when an operation fails.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.failure,
    this.message,
    this.onRetry,
    this.compact = false,
  }) : assert(failure != null || message != null);

  final Failure? failure;
  final String? message;
  final VoidCallback? onRetry;

  /// If true, renders a compact inline error instead of full-screen.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final displayMessage = message ?? _messageForFailure(failure!, context);

    if (compact) {
      return _CompactError(message: displayMessage, onRetry: onRetry);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconForFailure(failure),
              size: 56,
              color: context.colorScheme.error.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              displayMessage,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              JButton(
                label: context.l10n.retry,
                onPressed: onRetry,
                minimumSize: const Size(160, 44),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _messageForFailure(Failure f, BuildContext context) {
    return switch (f) {
      NetworkFailure() => context.l10n.errorNetwork,
      AuthFailure()    => context.l10n.errorForbidden,
      OfflineFailure() => context.l10n.noInternetConnection,
      _                => context.l10n.errorUnexpected,
    };
  }

  IconData _iconForFailure(Failure? f) {
    return switch (f) {
      NetworkFailure()  => Icons.wifi_off_rounded,
      OfflineFailure()  => Icons.cloud_off_rounded,
      NotFoundFailure() => Icons.search_off_rounded,
      ForbiddenFailure()=> Icons.lock_outline_rounded,
      _                 => Icons.error_outline_rounded,
    };
  }
}

class _CompactError extends StatelessWidget {
  const _CompactError({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: context.colorScheme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.error,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(context.l10n.retry),
            ),
        ],
      ),
    );
  }
}
