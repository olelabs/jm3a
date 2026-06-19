import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/notification_entity.dart';
import '../../presentation/notification_provider.dart';

/// Renders in-app toast notifications over the entire screen.
///
/// Place this inside the app shell widget tree (above the Navigator).
/// Toasts stack vertically (max 3) and auto-dismiss after 4 seconds.
///
/// Usage:
/// ```dart
/// Stack(
///   children: [
///     child,
///     const InAppToastOverlay(),
///   ],
/// )
/// ```
class InAppToastOverlay extends StatelessWidget {
  const InAppToastOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (ctx, notifs, _) {
        final toasts = notifs.toastQueue;
        if (toasts.isEmpty) return const SizedBox.shrink();

        return Positioned(
          top: MediaQuery.paddingOf(ctx).top + 8,
          left: 12,
          right: 12,
          child: Column(
            children: toasts
                .map(
                  (toast) => _ToastCard(
                    toast: toast,
                    onDismiss: () => notifs.dismissToast(toast.id),
                    onTap: () {
                      notifs.dismissToast(toast.id);
                      NotificationService.instance.routeFromPayload(toast.data);
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({
    required this.toast,
    required this.onDismiss,
    required this.onTap,
  });

  final InAppToast toast;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child:
          GestureDetector(
                onTap: onTap,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(14),
                  color: theme.colorScheme.surface,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withOpacity(
                          0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Type icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _typeColor(toast.type).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              toast.type.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                toast.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                toast.body,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          onPressed: onDismiss,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .slideY(
                begin: -1,
                end: 0,
                duration: 250.ms,
                curve: Curves.easeOutCubic,
              )
              .fadeIn(duration: 200.ms),
    );
  }

  Color _typeColor(NotificationType type) => switch (type) {
    NotificationType.friendRequest => AppColors.infoBlue,
    NotificationType.friendAccepted => AppColors.successGreen,
    NotificationType.roomInvite => AppColors.navyBlue,
    NotificationType.packSale => AppColors.tealGreen,
    NotificationType.walletCredit => AppColors.successGreen,
    _ => AppColors.navyBlue,
  };
}
