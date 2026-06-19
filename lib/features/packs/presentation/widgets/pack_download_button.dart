import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import 'package:jma3a/features/packs/data/pack_download_manager.dart';
import '../../domain/pack_entity.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/pack_entity.dart';

/// Adaptive download button that reflects current download state.
/// Compact mode: icon-only for list rows.
/// Full mode: labeled button for detail screens.
// class PackDownloadButton extends StatelessWidget {
//   const PackDownloadButton({
//     super.key,
//     required this.packId,
//     required this.state,
//     required this.onDownload,
//     required this.onDelete,
//     this.compact = false,
//   });

//   final String            packId;
//   final PackDownloadState state;
//   final VoidCallback      onDownload;
//   final VoidCallback      onDelete;
//   final bool              compact;

//   @override
//   Widget build(BuildContext context) {
//     return switch (state.status) {
//       DownloadStatus.notDownloaded => _DownloadCta(
//         compact:    compact,
//         onDownload: onDownload,
//       ),
//       DownloadStatus.downloading => _DownloadProgress(
//         progress: state.progress,
//         compact:  compact,
//       ),
//       DownloadStatus.downloaded => _DownloadedCta(
//         compact:  compact,
//         onDelete: onDelete,
//       ),
//       DownloadStatus.failed => _FailedCta(
//         compact:    compact,
//         onRetry:    onDownload,
//         errorMessage: state.errorMessage,
//       ),
//       DownloadStatus.expired => _DownloadCta(
//         compact:    compact,
//         onDownload: onDownload,
//         label: 'Re-download',
//       ),
//     };
//   }
// }
class PackDownloadButton extends StatelessWidget {
  const PackDownloadButton({
    super.key,
    required this.packId,
    required this.state,
    required this.onDownload,
    required this.onDelete,
    this.compact = false,
  });

  final String packId;
  final PackDownloadState state;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final bool compact;

  @override
  // Widget build(BuildContext context) {
  //   return switch (state.status) {
  //     DownloadStatus.notDownloaded => _DownloadCta(
  //       compact: compact,
  //       onDownload: onDownload,
  //     ),
  //     DownloadStatus.downloading => _DownloadProgress(
  //       progress: state.progress,
  //       compact: compact,
  //     ),
  //     DownloadStatus.downloaded => _DownloadedCta(
  //       compact: compact,
  //       onDelete: onDelete,
  //     ),
  //     DownloadStatus.failed => _FailedCta(
  //       compact: compact,
  //       onRetry: onDownload,
  //       errorMessage: state.errorMessage,
  //     ),
  //     DownloadStatus.expired => _DownloadCta(
  //       compact: compact,
  //       onDownload: onDownload,
  //       label: 'Re-download',
  //     ),
  //   };
  // }
  Widget build(BuildContext context) {
    return switch (state.status) {
      DownloadStatus.notDownloaded => _DownloadCta(
        compact: compact,
        onDownload: onDownload,
      ),
      DownloadStatus.downloading => _DownloadProgress(
        progress: state.progress,
        compact: compact,
      ),
      DownloadStatus.downloaded => _DownloadedCta(
        compact: compact,
        onDelete: onDelete,
      ),
      DownloadStatus.failed => _FailedCta(
        compact: compact,
        onRetry: onDownload,
        errorMessage: state.errorMessage,
      ),
      DownloadStatus.expired => _DownloadCta(
        compact: compact,
        onDownload: onDownload,
        label: 'Re-download',
      ),
    };
  }
}

// }

class _DownloadCta extends StatelessWidget {
  const _DownloadCta({
    required this.onDownload,
    this.compact = false,
    this.label = 'Download',
  });
  final VoidCallback onDownload;
  final bool compact;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        icon: const Icon(Icons.download_rounded),
        onPressed: onDownload,
        color: context.colorScheme.primary,
        tooltip: label,
      );
    }
    return OutlinedButton.icon(
      onPressed: onDownload,
      icon: const Icon(Icons.download_rounded),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }
}

class _DownloadProgress extends StatelessWidget {
  const _DownloadProgress({required this.progress, this.compact = false});
  final double progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress > 0 ? progress : null,
              strokeWidth: 2.5,
            ),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Downloading… ${(progress * 100).round()}%',
              style: context.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress > 0 ? progress : null,
          minHeight: 4,
          borderRadius: BorderRadius.circular(4),
          backgroundColor: context.colorScheme.surfaceContainerHighest,
          color: AppColors.successGreen,
        ),
      ],
    ).animate().fadeIn();
  }
}

extension on BuildContext {
  // ignore: unused_element
  get colorScheme => Theme.of(this).colorScheme;
  // ignore: unused_element
  get textTheme => Theme.of(this).textTheme;
}

class _DownloadedCta extends StatelessWidget {
  const _DownloadedCta({required this.onDelete, this.compact = false});
  final VoidCallback onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Tooltip(
        message: 'Available offline',
        child: Icon(
          Icons.offline_pin_rounded,
          color: AppColors.successGreen,
          size: 24,
        ),
      );
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.offline_pin_rounded,
                color: AppColors.successGreen,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Available offline',
                style: TextStyle(
                  color: AppColors.successGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onDelete,
          icon: Icon(
            Icons.delete_outline_rounded,
            size: 16,
            color: Colors.red.shade400,
          ),
          label: Text(
            'Remove download',
            style: TextStyle(color: Colors.red.shade400, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _FailedCta extends StatelessWidget {
  const _FailedCta({
    required this.onRetry,
    this.compact = false,
    this.errorMessage,
  });
  final VoidCallback onRetry;
  final bool compact;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        icon: const Icon(Icons.error_outline_rounded),
        onPressed: onRetry,
        color: AppColors.errorRed,
        tooltip: 'Retry download',
      );
    }
    return Column(
      children: [
        Text(
          'Download failed',
          style: TextStyle(
            color: AppColors.errorRed,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorMessage!,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.errorRed),
            foregroundColor: AppColors.errorRed,
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
      ],
    ).animate().fadeIn();
  }
}
