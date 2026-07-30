// import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:flutter/material.dart';

// import '../utils/app_logger.dart';

// /// Shows local notifications while the app is in the FOREGROUND, using
// /// awesome_notifications instead of relying on OneSignal's own banner.
// ///
// /// Split of responsibility:
// ///  - Foreground (app open):        LocalNotificationService (this file)
// ///  - Background / app terminated:  OneSignal (handled natively by the OS,
// ///                                   see NotificationService)
// ///
// /// NotificationService.dart's OneSignal foreground listener already calls
// /// `event.preventDefault()` to stop OneSignal's own banner from showing
// /// while the app is open — this service is what actually displays
// /// something to the user in that situation instead.
// class LocalNotificationService {
//   LocalNotificationService._();
//   static final LocalNotificationService _instance =
//       LocalNotificationService._();
//   static LocalNotificationService get instance => _instance;

//   static const String channelKey = 'jma3a_foreground_channel';
//   static const String channelGroupKey = 'jma3a_channel_group';

//   int _idCounter = 100000; // separate range from any other local IDs in use

//   /// Set externally (from the service locator, after both services exist)
//   /// to route notification taps the same way push-notification taps are
//   /// routed. Avoids a circular import between this file and
//   /// NotificationService.
//   void Function(Map<String, dynamic> data)? onTap;

//   Future<void> initialize() async {
//     await AwesomeNotifications().initialize(
//       // null = use the default app icon (mipmap/ic_launcher on Android).
//       // Replace with 'resource://drawable/ic_notification' if/when a
//       // dedicated monochrome notification icon is added to the project.
//       null,
//       [
//         NotificationChannel(
//           channelGroupKey: channelGroupKey,
//           channelKey: channelKey,
//           channelName: 'Jma3a Notifications',
//           channelDescription:
//               'Notifications shown while the app is open (friend requests, '
//               'room invites, wallet updates, pack sales, etc.)',
//           defaultColor: const Color(0xFF6C5CE7),
//           ledColor: Colors.white,
//           importance: NotificationImportance.High,
//           channelShowBadge: true,
//           playSound: true,
//           enableVibration: true,
//         ),
//       ],
//       channelGroups: [
//         NotificationChannelGroup(
//           channelGroupKey: channelGroupKey,
//           channelGroupName: 'Jma3a',
//         ),
//       ],
//       debug: false,
//     );

//     final isAllowed = await AwesomeNotifications().isNotificationAllowed();
//     if (!isAllowed) {
//       await AwesomeNotifications().requestPermissionToSendNotifications();
//     }

//     await AwesomeNotifications().setListeners(
//       onActionReceivedMethod: _onActionReceived,
//     );

//     AppLogger.info('LocalNotificationService: initialized');
//   }

//   /// Show a local notification while the app is in the foreground.
//   /// Mirrors the same (type, title, body, data) shape used elsewhere so it
//   /// can be called directly from NotificationService's OneSignal foreground
//   /// handler with no payload translation needed.
//   Future<void> show({
//     required String title,
//     required String body,
//     required Map<String, dynamic> data,
//   }) async {
//     _idCounter++;
//     try {
//       await AwesomeNotifications().createNotification(
//         content: NotificationContent(
//           id: _idCounter,
//           channelKey: channelKey,
//           title: title,
//           body: body,
//           notificationLayout: NotificationLayout.Default,
//           payload: data.map((k, v) => MapEntry(k, v?.toString() ?? '')),
//         ),
//       );
//     } catch (e, st) {
//       AppLogger.error(
//         'LocalNotificationService: failed to show notification',
//         error: e,
//         stackTrace: st,
//       );
//     }
//   }

//   // awesome_notifications requires top-level/static entry points for its
//   // action callbacks (they may run in a background isolate).
//   @pragma('vm:entry-point')
//   static Future<void> _onActionReceived(ReceivedAction action) async {
//     final payload = action.payload ?? <String, String?>{};
//     _instance.onTap?.call(Map<String, dynamic>.from(payload));
//   }
// }

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

import '../utils/app_logger.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  void Function(Map<String, dynamic>)? onTap;
  static const _channelKey = 'jma3a_main';

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: _channelKey,
        channelName: 'Jma3a Notifications',
        channelDescription: 'Game invitations and activity',
        defaultColor: const Color(0xFF6C63FF),
        ledColor: const Color(0xFF6C63FF),
        importance: NotificationImportance.High,
        channelShowBadge: true,
        playSound: true,
        enableVibration: true,
      ),
    ]);

    AwesomeNotifications().setListeners(onActionReceivedMethod: _onAction);

    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    AppLogger.info('LocalNotificationService: initialized');
  }

  @pragma('vm:entry-point')
  static Future<void> _onAction(ReceivedAction action) async {
    final payload = action.payload ?? {};
    final data = <String, dynamic>{
      for (final e in payload.entries) e.key: e.value,
    };
    LocalNotificationService.instance.onTap?.call(data);
  }

  Future<void> show({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final payload = <String, String>{};
      if (data != null) {
        for (final entry in data.entries) {
          if (entry.value != null) {
            payload[entry.key] = entry.value.toString();
          }
        }
      }
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: _channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          payload: payload,
          autoDismissible: true,
        ),
      );
    } catch (e) {
      AppLogger.warning('LocalNotificationService.show failed: $e');
    }
  }
}
