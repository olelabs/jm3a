// // import 'package:supabase_flutter/supabase_flutter.dart';
// // import '../../../core/data/base_repository.dart';

// // class NotificationEntity {
// //   const NotificationEntity({required this.id, required this.userId, required this.type, required this.titleJson, required this.bodyJson, required this.data, required this.isRead, required this.createdAt});
// //   final String id;
// //   final String userId;
// //   final String type;
// //   final Map<String, dynamic> titleJson;
// //   final Map<String, dynamic> bodyJson;
// //   final Map<String, dynamic> data;
// //   final bool isRead;
// //   final DateTime createdAt;
// //   String titleFor(String lang) => titleJson[lang] as String? ?? titleJson['en'] as String? ?? '';
// //   String bodyFor(String lang) => bodyJson[lang] as String? ?? bodyJson['en'] as String? ?? '';
// // }

// // class NotificationRepository extends BaseRepository {
// //   NotificationRepository._();
// //   static final NotificationRepository _instance = NotificationRepository._();
// //   static NotificationRepository get instance => _instance;
// //   final _supabase = Supabase.instance.client;

// //   Future<List<NotificationEntity>> getNotifications(String userId, {int limit = 30}) => guardedCall(
// //     operationName: 'getNotifications',
// //     operation: () async {
// //       final rows = await _supabase.from('notifications').select().eq('user_id', userId).isFilter('deleted_at',null).order('created_at', ascending: false).limit(limit);
// //       return rows.map(_toEntity).toList();
// //     });

// //   Future<void> markRead(String notificationId) => guardedCall(
// //     operationName: 'markRead',
// //     operation: () async => _supabase.from('notifications').update({'is_read': true}).eq('id', notificationId));

// //   Future<void> markAllRead(String userId) => guardedCall(
// //     operationName: 'markAllRead',
// //     operation: () async => _supabase.from('notifications').update({'is_read': true}).eq('user_id', userId).eq('is_read', false));

// //   NotificationEntity _toEntity(Map<String, dynamic> r) => NotificationEntity(
// //     id: r['id'] as String, userId: r['user_id'] as String, type: r['type'] as String,
// //     titleJson: (r['title'] as Map?)?.cast<String,dynamic>() ?? {},
// //     bodyJson: (r['body'] as Map?)?.cast<String,dynamic>() ?? {},
// //     data: (r['data'] as Map?)?.cast<String,dynamic>() ?? {},
// //     isRead: r['is_read'] as bool? ?? false,
// //     createdAt: DateTime.parse(r['created_at'] as String));
// // }

// import 'package:jma3a/features/notifications/domain/notification_entity.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../../core/data/base_repository.dart';
// // import '../domain/notification_entity.dart';

// // export '../domain/notification_entity.dart';

// class NotificationRepository extends BaseRepository {
//   NotificationRepository._();
//   static final NotificationRepository _instance = NotificationRepository._();
//   static NotificationRepository get instance => _instance;

//   final _supabase = Supabase.instance.client;

//   // ── Notifications ──────────────────────────────────────────────────────────

//   Future<List<NotificationEntity>> getNotifications(
//     String userId, {
//     int limit = 40,
//     int offset = 0,
//   }) => guardedCall(
//     operationName: 'getNotifications',
//     operation: () async {
//       final rows = await _supabase
//           .from('notifications')
//           .select()
//           .eq('user_id', userId)
//           .isFilter('deleted_at', null)
//           .gt('expires_at', DateTime.now().toIso8601String())
//           .order('created_at', ascending: false)
//           .range(offset, offset + limit - 1);
//       return rows.map(_toEntity).toList();
//     },
//   );

//   Future<void> markRead(String notificationId) => guardedCall(
//     operationName: 'markRead',
//     operation: () async {
//       await _supabase
//           .from('notifications')
//           .update({'is_read': true})
//           .eq('id', notificationId);
//     },
//   );

//   Future<void> markAllRead(String userId) => guardedCall(
//     operationName: 'markAllRead',
//     operation: () async {
//       await _supabase
//           .from('notifications')
//           .update({'is_read': true})
//           .eq('user_id', userId)
//           .eq('is_read', false);
//     },
//   );

//   Future<void> deleteNotification(String notificationId) => guardedCall(
//     operationName: 'deleteNotification',
//     operation: () async {
//       await _supabase
//           .from('notifications')
//           .update({'deleted_at': DateTime.now().toIso8601String()})
//           .eq('id', notificationId);
//     },
//   );

//   // ── Preferences ───────────────────────────────────────────────────────────

//   Future<List<NotificationPreference>> getPreferences(String userId) =>
//       guardedCall(
//         operationName: 'getPreferences',
//         operation: () async {
//           final rows = await _supabase
//               .from('notification_preferences')
//               .select()
//               .eq('user_id', userId);

//           // Build map from DB
//           final prefsMap = <String, NotificationPreference>{};
//           for (final row in rows) {
//             final type = row['notification_type'] as String?;
//             if (type != null) {
//               prefsMap[type] = NotificationPreference(
//                 type: NotificationType.fromString(type),
//                 inApp: row['in_app'] as bool? ?? true,
//                 push: row['push'] as bool? ?? true,
//               );
//             }
//           }

//           // Return all types, filling defaults for missing ones
//           return NotificationType.values.map((t) {
//             return prefsMap[t.dbString] ??
//                 NotificationPreference(type: t, inApp: true, push: true);
//           }).toList();
//         },
//       );

//   Future<void> updatePreference({
//     required String userId,
//     required NotificationType type,
//     required bool inApp,
//     required bool push,
//   }) => guardedCall(
//     operationName: 'updatePreference',
//     operation: () async {
//       await _supabase.from('notification_preferences').upsert({
//         'user_id': userId,
//         'notification_type': type.dbString,
//         'in_app': inApp,
//         'push': push,
//       }, onConflict: 'user_id,notification_type');
//     },
//   );

//   // ── Mapper ────────────────────────────────────────────────────────────────

//   NotificationEntity _toEntity(Map<String, dynamic> r) => NotificationEntity(
//     id: r['id'] as String,
//     userId: r['user_id'] as String,
//     type: NotificationType.fromString(r['type'] as String? ?? 'system'),
//     titleJson: (r['title'] as Map?)?.cast<String, dynamic>() ?? {},
//     bodyJson: (r['body'] as Map?)?.cast<String, dynamic>() ?? {},
//     data: (r['data'] as Map?)?.cast<String, dynamic>() ?? {},
//     isRead: r['is_read'] as bool? ?? false,
//     createdAt: DateTime.parse(r['created_at'] as String),
//     expiresAt: r['expires_at'] != null
//         ? DateTime.tryParse(r['expires_at'] as String)
//         : null,
//   );
// }

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import '../domain/notification_entity.dart';

export '../domain/notification_entity.dart';

class NotificationRepository extends BaseRepository {
  NotificationRepository._();
  static final NotificationRepository _instance = NotificationRepository._();
  static NotificationRepository get instance => _instance;

  final _supabase = Supabase.instance.client;

  // ── Notifications ──────────────────────────────────────────────────────────

  Future<List<NotificationEntity>> getNotifications(
    String userId, {
    int limit = 40,
    int offset = 0,
  }) => guardedCall(
    operationName: 'getNotifications',
    operation: () async {
      final rows = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return rows.map(_toEntity).toList();
    },
  );

  Future<void> markRead(String notificationId) => guardedCall(
    operationName: 'markRead',
    operation: () async {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    },
  );

  Future<void> markAllRead(String userId) => guardedCall(
    operationName: 'markAllRead',
    operation: () async {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    },
  );

  Future<void> deleteNotification(String notificationId) => guardedCall(
    operationName: 'deleteNotification',
    operation: () async {
      await _supabase
          .from('notifications')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);
    },
  );

  // ── Preferences ───────────────────────────────────────────────────────────

  Future<List<NotificationPreference>> getPreferences(String userId) =>
      guardedCall(
        operationName: 'getPreferences',
        operation: () async {
          final rows = await _supabase
              .from('notification_preferences')
              .select()
              .eq('user_id', userId);

          // Build map from DB
          final prefsMap = <String, NotificationPreference>{};
          for (final row in rows) {
            // ✅ FIX: schema column is `type`, not `notification_type`.
            // Reading the wrong column meant this map was always empty,
            // so every preference silently fell back to the hardcoded
            // default below — toggles never actually reflected saved state.
            final type = row['type'] as String?;
            if (type != null) {
              prefsMap[type] = NotificationPreference(
                type: NotificationType.fromString(type),
                inApp: row['in_app'] as bool? ?? true,
                push: row['push'] as bool? ?? true,
              );
            }
          }

          // Return all types, filling defaults for missing ones
          return NotificationType.values.map((t) {
            return prefsMap[t.dbString] ??
                NotificationPreference(type: t, inApp: true, push: true);
          }).toList();
        },
      );

  Future<void> updatePreference({
    required String userId,
    required NotificationType type,
    required bool inApp,
    required bool push,
  }) => guardedCall(
    operationName: 'updatePreference',
    operation: () async {
      // ✅ FIX: same column-name bug as getPreferences — was writing to
      // a non-existent 'notification_type' column, so toggling a
      // setting never actually persisted anything.
      await _supabase.from('notification_preferences').upsert({
        'user_id': userId,
        'type': type.dbString,
        'in_app': inApp,
        'push': push,
      }, onConflict: 'user_id,type');
    },
  );

  // ── Mapper ────────────────────────────────────────────────────────────────

  NotificationEntity _toEntity(Map<String, dynamic> r) => NotificationEntity(
    id: r['id'] as String,
    userId: r['user_id'] as String,
    type: NotificationType.fromString(r['type'] as String? ?? 'system'),
    titleJson: (r['title'] as Map?)?.cast<String, dynamic>() ?? {},
    bodyJson: (r['body'] as Map?)?.cast<String, dynamic>() ?? {},
    data: (r['data'] as Map?)?.cast<String, dynamic>() ?? {},
    isRead: r['is_read'] as bool? ?? false,
    createdAt: DateTime.parse(r['created_at'] as String),
    expiresAt: r['expires_at'] != null
        ? DateTime.tryParse(r['expires_at'] as String)
        : null,
  );
}
