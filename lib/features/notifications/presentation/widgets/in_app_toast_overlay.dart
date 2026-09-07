import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../presentation/notification_provider.dart';

/// Renders modern in-app notification banners over the entire screen while
/// the app is in the foreground.
///
/// Mounted once, at the root of the widget tree (see `_AppShell` in
/// `app.dart`, alongside the offline banner) — above the `Navigator`, so it
/// overlays every route without needing to be re-added per screen. Scoped
/// to its own `Consumer<NotificationProvider>`, so only this small overlay
/// subtree rebuilds when the toast queue changes; the rest of the app
/// (`widget.child`) is untouched.
///
/// Toasts stack vertically (max 3, newest on top) and each owns its own
/// entrance/exit animation and auto-dismiss timer — see [_ToastBanner].
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
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: toasts
                  .map(
                    (toast) => _ToastBanner(
                      key: ValueKey(toast.id),
                      toast: toast,
                      onDismiss: () => notifs.dismissToast(toast.id),
                      onTap: () {
                        notifs.dismissToast(toast.id);
                        NotificationService.instance.routeFromPayload(
                          toast.data,
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}

/// A single animated, swipeable, auto-dismissing notification banner.
///
/// Owns its own [AnimationController] (entrance + exit) and auto-dismiss
/// [Timer] — both are cancelled/disposed in [dispose], so nothing leaks if
/// the toast is removed from the queue externally (e.g. on logout, via
/// `NotificationProvider.clearAllToasts`) while still on screen.
class _ToastBanner extends StatefulWidget {
  const _ToastBanner({
    super.key,
    required this.toast,
    required this.onDismiss,
    required this.onTap,
  });

  final InAppToast toast;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  @override
  State<_ToastBanner> createState() => _ToastBannerState();
}

class _ToastBannerState extends State<_ToastBanner>
    with SingleTickerProviderStateMixin {
  static const _visibleDuration = Duration(seconds: 5);

  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _autoDismissTimer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _slide = Tween<Offset>(begin: const Offset(0, -0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _controller.forward();
    _autoDismissTimer = Timer(_visibleDuration, _dismiss);
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    _autoDismissTimer?.cancel();
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  void _handleTap() {
    _autoDismissTimer?.cancel();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Dismissible(
            key: ValueKey('dismissible-${widget.toast.id}'),
            direction: DismissDirection.horizontal,
            onDismissed: (_) {
              _dismissing = true;
              _autoDismissTimer?.cancel();
              widget.onDismiss();
            },
            child: _ToastCard(
              toast: widget.toast,
              onTap: _handleTap,
              onClose: _dismiss,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({
    required this.toast,
    required this.onTap,
    required this.onClose,
  });

  final InAppToast toast;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;
    final lang = Localizations.localeOf(context).languageCode;
    final color = _typeColor(toast.type);

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(context.isDarkMode ? 0.72 : 0.86),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      context.isDarkMode ? 0.35 : 0.14,
                    ),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Leading(toast: toast, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                toast.titleFor(lang),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _relativeTime(context, toast.createdAt),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          toast.bodyFor(lang),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    visualDensity: VisualDensity.compact,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _relativeTime(BuildContext context, DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return context.l10n.notifJustNow;
    return context.l10n.notifMinutesAgo(diff.inMinutes);
  }

  Color _typeColor(NotificationType type) => switch (type) {
    NotificationType.friendRequest => AppColors.infoBlue,
    NotificationType.friendAccepted => AppColors.successGreen,
    NotificationType.roomInvite => AppColors.navyBlue,
    NotificationType.packSale => AppColors.tealGreen,
    NotificationType.walletCredit => AppColors.successGreen,
    NotificationType.moderation => AppColors.warningAmber,
    NotificationType.achievement => AppColors.amberOrangeLight,
    NotificationType.follow => AppColors.infoBlue,
    NotificationType.packReview => AppColors.memeYellow,
    NotificationType.packExpired => AppColors.errorRed,
    NotificationType.physicalPackStatus => AppColors.tealGreen,
    NotificationType.subscriptionStarted => AppColors.brandPurpleMid,
    NotificationType.subscriptionExpiring2d => AppColors.warningAmber,
    NotificationType.subscriptionExpiring1d => AppColors.warningAmber,
    NotificationType.subscriptionExpired => AppColors.errorRed,
    NotificationType.roomJoinRequest => AppColors.navyBlue,
    NotificationType.roomJoinRequestAccepted => AppColors.successGreen,
    NotificationType.roomJoinRequestRejected => AppColors.errorRed,
    NotificationType.roomKicked => AppColors.errorRed,
    NotificationType.creatorPacksTransferred => AppColors.warningAmber,
    NotificationType.creatorPrivilegesRemoved => AppColors.errorRed,
    NotificationType.creatorRecoveryApproved => AppColors.successGreen,
    NotificationType.creatorRecoveryRejected => AppColors.errorRed,
    NotificationType.streakIncreased => AppColors.amberOrangeLight,
    _ => AppColors.navyBlue,
  };
}

/// Sender avatar when the payload has one (e.g. a friend-request notice
/// carrying the requester's `avatar_url`); otherwise a tinted circle with
/// the notification type's icon.
class _Leading extends StatelessWidget {
  const _Leading({required this.toast, required this.color});

  final InAppToast toast;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = toast.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatarUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _TypeIcon(type: toast.type, color: color),
        ),
      );
    }
    return _TypeIcon(type: toast.type, color: color);
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type, required this.color});

  final NotificationType type;
  final Color color;

  IconData get _icon => switch (type) {
    NotificationType.friendRequest => Icons.person_add_alt_1_rounded,
    NotificationType.friendAccepted => Icons.people_alt_rounded,
    NotificationType.roomInvite => Icons.videogame_asset_rounded,
    NotificationType.roomStarted => Icons.play_circle_fill_rounded,
    NotificationType.packApproved => Icons.inventory_2_rounded,
    NotificationType.packRejected => Icons.cancel_rounded,
    NotificationType.packSale => Icons.payments_rounded,
    NotificationType.walletCredit => Icons.account_balance_wallet_rounded,
    NotificationType.walletDebit => Icons.account_balance_wallet_outlined,
    NotificationType.moderation => Icons.shield_rounded,
    NotificationType.achievement => Icons.emoji_events_rounded,
    NotificationType.system => Icons.campaign_rounded,
    NotificationType.follow => Icons.person_add_rounded,
    NotificationType.packReview => Icons.star_rounded,
    NotificationType.packExpired => Icons.inventory_2_outlined,
    NotificationType.physicalPackStatus => Icons.local_shipping_rounded,
    NotificationType.subscriptionStarted => Icons.workspace_premium_rounded,
    NotificationType.subscriptionExpiring2d => Icons.hourglass_bottom_rounded,
    NotificationType.subscriptionExpiring1d => Icons.hourglass_bottom_rounded,
    NotificationType.subscriptionExpired => Icons.workspace_premium_outlined,
    NotificationType.roomJoinRequest => Icons.group_add_rounded,
    NotificationType.roomJoinRequestAccepted => Icons.check_circle_rounded,
    NotificationType.roomJoinRequestRejected => Icons.block_rounded,
    NotificationType.roomKicked => Icons.exit_to_app_rounded,
    NotificationType.creatorPacksTransferred => Icons.inventory_2_rounded,
    NotificationType.creatorPrivilegesRemoved => Icons.verified_outlined,
    NotificationType.creatorRecoveryApproved => Icons.verified_rounded,
    NotificationType.creatorRecoveryRejected => Icons.cancel_outlined,
    NotificationType.chatMessage => Icons.chat_bubble_rounded,
    NotificationType.streakIncreased => Icons.local_fire_department_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(_icon, size: 20, color: color),
    );
  }
}
