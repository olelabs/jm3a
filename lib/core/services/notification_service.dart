import 'package:jma3a/core/config/app_config.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../router/app_router.dart';
import '../router/route_names.dart';
import '../utils/app_logger.dart';
import '../../features/notifications/domain/notification_entity.dart';

/// Bridges OneSignal ↔ the app.
///
/// Foreground: suppress OS banner → inject InAppToast via NotificationProvider.
/// Background/killed: OS handles display; tap routes via _routeFromPayload.
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  // Injected by main.dart after provider tree is ready
  void Function(NotificationType, String, String, Map<String, dynamic>)?
  _onForeground;

  Future<void> initialize({required String appId}) async {
    OneSignal.initialize(appId);
    await OneSignal.Notifications.requestPermission(true);

    OneSignal.Notifications.addForegroundWillDisplayListener(_handleForeground);
    OneSignal.Notifications.addClickListener(_handleTap);

    AppLogger.info('NotificationService: initialized');
    print("OS App ID: ${AppConfig.oneSignalAppId}");
    print("Push ID: ${OneSignal.User.pushSubscription.id}");
    print("Token: ${OneSignal.User.pushSubscription.token}");
    print("OptedIn: ${OneSignal.User.pushSubscription.optedIn}");
  }

  /// Called after the provider tree is built.
  /// Passes the toast injection callback from NotificationProvider.
  void registerForegroundHandler(
    void Function(NotificationType, String, String, Map<String, dynamic>)
    handler,
  ) {
    _onForeground = handler;
  }

  void setExternalUserId(String userId) {
    OneSignal.login(userId);
    AppLogger.info('OneSignal: logged in as $userId');
  }

  void logout() {
    OneSignal.logout();
  }

  // ── Foreground ─────────────────────────────────────────────────────────────
  void _handleForeground(OSNotificationWillDisplayEvent event) {
    // Prevent OS from showing its own banner
    event.preventDefault();

    final data = event.notification.additionalData ?? {};
    final title = event.notification.title ?? '';
    final body = event.notification.body ?? '';
    final type = NotificationType.fromString(
      data['type'] as String? ?? 'system',
    );

    AppLogger.debug('Foreground notification: ${type.name}');

    // Inject into NotificationProvider's toast queue
    _onForeground?.call(type, title, body, Map<String, dynamic>.from(data));
  }

  // ── Tap ────────────────────────────────────────────────────────────────────
  void _handleTap(OSNotificationClickEvent event) {
    final data = event.notification.additionalData ?? {};
    AppLogger.info('Notification tap: $data');
    _routeFromPayload(Map<String, dynamic>.from(data));
  }

  void routeFromPayload(Map<String, dynamic> data) {
    _routeFromPayload(data);
  }

  void _routeFromPayload(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final roomId = data['room_id'] as String?;
    final router = AppRouter.router;

    switch (type) {
      case 'room_invite':
        if (roomId != null) {
          router.go('${RouteNames.home}/room/$roomId');
        } else {
          router.go(RouteNames.home);
        }
      case 'friend_request':
      case 'friend_accepted':
        router.go(RouteNames.friends);
      case 'wallet_credit':
      case 'wallet_debit':
        router.go(RouteNames.wallet);
      case 'pack_sale':
      case 'pack_approved':
      case 'pack_rejected':
        router.go(RouteNames.marketplace);
      case 'moderation':
        router.go(RouteNames.home);
      default:
        router.go(RouteNames.notifications);
    }
  }
}
