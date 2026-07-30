// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/services/notification_service.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../shared/widgets/feedback/error_view.dart';
// import '../../domain/notification_entity.dart';
// import '../../presentation/notification_provider.dart';

// class NotificationsScreen extends StatefulWidget {
//   const NotificationsScreen({super.key});

//   @override
//   State<NotificationsScreen> createState() => _NotificationsScreenState();
// }

// class _NotificationsScreenState extends State<NotificationsScreen> {
//   final _scrollCtrl = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     _scrollCtrl.addListener(_onScroll);
//   }

//   @override
//   void dispose() {
//     _scrollCtrl.dispose();
//     super.dispose();
//   }

//   void _onScroll() {
//     if (_scrollCtrl.position.pixels >=
//         _scrollCtrl.position.maxScrollExtent - 120) {
//       context.read<NotificationProvider>().loadMore();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Notifications'),
//         actions: [
//           Consumer<NotificationProvider>(
//             builder: (_, notifs, __) => notifs.unreadCount > 0
//                 ? TextButton(
//                     onPressed: notifs.markAllRead,
//                     child: const Text('Mark all read'),
//                   )
//                 : const SizedBox.shrink(),
//           ),
//           IconButton(
//             icon: const Icon(Icons.tune_rounded),
//             onPressed: () => Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => ChangeNotifierProvider.value(
//                   value: context.read<NotificationProvider>(),
//                   child: const NotificationPreferencesScreen(),
//                 ),
//               ),
//             ),
//             tooltip: 'Preferences',
//           ),
//         ],
//       ),
//       body: Consumer<NotificationProvider>(
//         builder: (ctx, notifs, _) {
//           if (notifs.isLoading && notifs.notifications.isEmpty) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (notifs.failure != null && notifs.notifications.isEmpty) {
//             return ErrorView(
//               message: notifs.failure!.message,
//               onRetry: notifs.refresh,
//             );
//           }
//           if (notifs.notifications.isEmpty) {
//             return Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text('🔔', style: TextStyle(fontSize: 56)),
//                   const SizedBox(height: 16),
//                   Text('No notifications',
//                       style: ctx.textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.w700)),
//                   const SizedBox(height: 8),
//                   Text("You're all caught up!",
//                       style: ctx.textTheme.bodyMedium?.copyWith(
//                           color: ctx.colorScheme.onSurfaceVariant)),
//                 ],
//               ),
//             );
//           }

//           return RefreshIndicator(
//             onRefresh: notifs.refresh,
//             child: ListView.separated(
//               controller: _scrollCtrl,
//               padding: const EdgeInsets.symmetric(vertical: 8),
//               itemCount: notifs.notifications.length +
//                   (notifs.isLoadingMore ? 1 : 0),
//               separatorBuilder: (_, __) =>
//                   const Divider(height: 1, indent: 72),
//               itemBuilder: (_, i) {
//                 if (i == notifs.notifications.length) {
//                   return const Padding(
//                     padding: EdgeInsets.all(16),
//                     child: Center(child: CircularProgressIndicator()),
//                   );
//                 }
//                 return NotificationTile(
//                   notification: notifs.notifications[i],
//                   onTap: () {
//                     notifs.markRead(notifs.notifications[i].id);
//                     NotificationService.instance
//                         .routeFromPayload(notifs.notifications[i].data);
//                   },
//                   onDismiss: () =>
//                       notifs.deleteNotification(notifs.notifications[i].id),
//                 ).animate(delay: (i * 15).ms).fadeIn();
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// // ── Notification tile ─────────────────────────────────────────────────────────
// class NotificationTile extends StatelessWidget {
//   const NotificationTile({
//     super.key,
//     required this.notification,
//     required this.onTap,
//     required this.onDismiss,
//   });

//   final NotificationEntity notification;
//   final VoidCallback        onTap;
//   final VoidCallback        onDismiss;

//   @override
//   Widget build(BuildContext context) {
//     final theme   = context.theme;
//     final isUnread = !notification.isRead;

//     return Dismissible(
//       key:        ValueKey(notification.id),
//       direction:  DismissDirection.endToStart,
//       background: Container(
//         alignment: Alignment.centerRight,
//         color:     AppColors.errorRed.withOpacity(0.15),
//         padding:   const EdgeInsets.only(right: 16),
//         child: const Icon(Icons.delete_outline_rounded,
//             color: AppColors.errorRed),
//       ),
//       onDismissed: (_) => onDismiss(),
//       child: InkWell(
//         onTap: onTap,
//         child: Container(
//           color: isUnread
//               ? theme.colorScheme.primaryContainer.withOpacity(0.08)
//               : null,
//           padding: const EdgeInsets.symmetric(
//               horizontal: 16, vertical: 12),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Type icon
//               Container(
//                 width: 40, height: 40,
//                 decoration: BoxDecoration(
//                   color:  theme.colorScheme.surfaceContainerHighest,
//                   shape:  BoxShape.circle,
//                 ),
//                 child: Center(
//                   child: Text(notification.type.emoji,
//                       style: const TextStyle(fontSize: 18)),
//                 ),
//               ),
//               const SizedBox(width: 12),

//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             notification.titleFor('en'),
//                             style: theme.textTheme.titleSmall?.copyWith(
//                               fontWeight: isUnread
//                                   ? FontWeight.w700
//                                   : FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                         Text(
//                           _formatDate(notification.createdAt),
//                           style: theme.textTheme.bodySmall?.copyWith(
//                               color: theme.colorScheme.onSurfaceVariant),
//                         ),
//                         if (isUnread) ...[
//                           const SizedBox(width: 6),
//                           Container(
//                             width: 8, height: 8,
//                             decoration: const BoxDecoration(
//                               color: AppColors.infoBlue,
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                     Text(
//                       notification.bodyFor('en'),
//                       style: theme.textTheme.bodySmall?.copyWith(
//                           color: theme.colorScheme.onSurfaceVariant,
//                           height: 1.4),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   String _formatDate(DateTime dt) {
//     final diff = DateTime.now().difference(dt);
//     if (diff.inMinutes < 60) return '${diff.inMinutes}m';
//     if (diff.inHours < 24)   return '${diff.inHours}h';
//     if (diff.inDays < 7)     return '${diff.inDays}d';
//     return '${dt.day}/${dt.month}';
//   }
// }

// // ── Notification preferences screen ──────────────────────────────────────────
// class NotificationPreferencesScreen extends StatelessWidget {
//   const NotificationPreferencesScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Notification Preferences')),
//       body: Consumer<NotificationProvider>(
//         builder: (ctx, notifs, _) {
//           return ListView(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
//                 child: Row(
//                   children: [
//                     const Expanded(child: SizedBox()),
//                     SizedBox(
//                       width: 60,
//                       child: Text('In-App',
//                           style: ctx.textTheme.labelSmall?.copyWith(
//                               color: ctx.colorScheme.onSurfaceVariant),
//                           textAlign: TextAlign.center),
//                     ),
//                     SizedBox(
//                       width: 60,
//                       child: Text('Push',
//                           style: ctx.textTheme.labelSmall?.copyWith(
//                               color: ctx.colorScheme.onSurfaceVariant),
//                           textAlign: TextAlign.center),
//                     ),
//                   ],
//                 ),
//               ),
//               const Divider(height: 1),
//               ...NotificationType.values.map((type) {
//                 final pref = notifs.preferences
//                     .cast<NotificationPreference?>()
//                     .firstWhere((p) => p?.type == type, orElse: () => null) ??
//                     NotificationPreference(type: type, inApp: true, push: true);

//                 return _PrefRow(
//                   pref:      pref,
//                   onChanged: (inApp, push) =>
//                       notifs.updatePreference(
//                           type: type, inApp: inApp, push: push),
//                 );
//               }),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// class _PrefRow extends StatelessWidget {
//   const _PrefRow({required this.pref, required this.onChanged});
//   final NotificationPreference pref;
//   final void Function(bool inApp, bool push) onChanged;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       decoration: BoxDecoration(
//         border: Border(
//           bottom: BorderSide(
//             color: context.colorScheme.outlineVariant.withOpacity(0.5)),
//         ),
//       ),
//       child: Row(
//         children: [
//           Text(pref.type.emoji,
//               style: const TextStyle(fontSize: 18)),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(pref.type.displayLabel,
//                 style: context.textTheme.bodyMedium),
//           ),
//           SizedBox(
//             width: 60,
//             child: Center(
//               child: Switch.adaptive(
//                 value:     pref.inApp,
//                 onChanged: (v) => onChanged(v, pref.push),
//               ),
//             ),
//           ),
//           SizedBox(
//             width: 60,
//             child: Center(
//               child: Switch.adaptive(
//                 value:     pref.push,
//                 onChanged: (v) => onChanged(pref.inApp, v),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../../domain/notification_entity.dart';
import '../../presentation/notification_provider.dart';

/// Outstanding room invites the user hasn't acted on yet — surfaced as a
/// standing list so a user isn't limited to reacting to a single push/
/// toast per invite (which is easy to miss or dismiss by accident).
class PendingInvitesSection extends StatefulWidget {
  const PendingInvitesSection({super.key});
  @override
  State<PendingInvitesSection> createState() => _PendingInvitesSectionState();
}

class _PendingInvitesSectionState extends State<PendingInvitesSection> {
  List<Map<String, dynamic>> _invites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final rows = await sl.roomRepository.getPendingInvites(userId);
      if (mounted)
        setState(() {
          _invites = rows;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decline(String roomId) async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    try {
      await sl.roomRepository.declineInvite(userId: userId, roomId: roomId);
      await _load();
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _invites.isEmpty) return const SizedBox.shrink();
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Room Invites (${_invites.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ..._invites.map((inv) {
            final roomId = inv['room_id'] as String;
            final room = inv['rooms'] as Map<String, dynamic>? ?? {};
            final roomName = room['name'] as String? ?? 'a room';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(
                  Icons.mail_rounded,
                  color: AppColors.tealGreen,
                ),
                title: Text(roomName),
                subtitle: const Text('Invited you to join'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                      tooltip: 'Decline',
                      onPressed: () => _decline(roomId),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                      ),
                      tooltip: 'View',
                      // Reuses the exact same validate-then-enter-the-room
                      // logic every notification trigger uses — no
                      // intermediate confirmation screen, no duplicated
                      // navigation logic.
                      onPressed: () =>
                          NotificationService.instance.routeFromPayload({
                            'type': 'room_invite',
                            'room_id': roomId,
                          }),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Divider(),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 120) {
      context.read<NotificationProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, notifs, __) => notifs.unreadCount > 0
                ? TextButton(
                    onPressed: notifs.markAllRead,
                    child: const Text('Mark all read'),
                  )
                : const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: context.read<NotificationProvider>(),
                  child: const NotificationPreferencesScreen(),
                ),
              ),
            ),
            tooltip: 'Preferences',
          ),
        ],
      ),
      body: Column(
        children: [
          const PendingInvitesSection(),
          Expanded(
            child: Consumer<NotificationProvider>(
              builder: (ctx, notifs, _) {
                if (notifs.isLoading && notifs.notifications.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (notifs.failure != null && notifs.notifications.isEmpty) {
                  return ErrorView(
                    message: notifs.failure!.message,
                    onRetry: notifs.refresh,
                  );
                }
                if (notifs.notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔔', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: ctx.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "You're all caught up!",
                          style: ctx.textTheme.bodyMedium?.copyWith(
                            color: ctx.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: notifs.refresh,
                  child: ListView.separated(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount:
                        notifs.notifications.length +
                        (notifs.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) {
                      if (i == notifs.notifications.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return NotificationTile(
                        notification: notifs.notifications[i],
                        onTap: () {
                          notifs.markRead(notifs.notifications[i].id);
                          final n = notifs.notifications[i];
                          NotificationService.instance.routeFromPayload({
                            'type': n.type.dbString,
                            ...n.data,
                          });
                        },
                        onDismiss: () => notifs.deleteNotification(
                          notifs.notifications[i].id,
                        ),
                      ).animate(delay: (i * 15).ms).fadeIn();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isUnread = !notification.isRead;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: AppColors.errorRed.withOpacity(0.15),
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.errorRed,
        ),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: isUnread
              ? theme.colorScheme.primaryContainer.withOpacity(0.08)
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    notification.type.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.titleFor('en'),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(notification.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.infoBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      notification.bodyFor('en'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }
}

// ── Notification preferences screen ──────────────────────────────────────────
class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: Consumer<NotificationProvider>(
        builder: (ctx, notifs, _) {
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    SizedBox(
                      width: 60,
                      child: Text(
                        'In-App',
                        style: ctx.textTheme.labelSmall?.copyWith(
                          color: ctx.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        'Push',
                        style: ctx.textTheme.labelSmall?.copyWith(
                          color: ctx.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...NotificationType.values.map((type) {
                final pref =
                    notifs.preferences
                        .cast<NotificationPreference?>()
                        .firstWhere(
                          (p) => p?.type == type,
                          orElse: () => null,
                        ) ??
                    NotificationPreference(type: type, inApp: true, push: true);

                return _PrefRow(
                  pref: pref,
                  onChanged: (inApp, push) => notifs.updatePreference(
                    type: type,
                    inApp: inApp,
                    push: push,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  const _PrefRow({required this.pref, required this.onChanged});
  final NotificationPreference pref;
  final void Function(bool inApp, bool push) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(pref.type.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pref.type.displayLabel,
              style: context.textTheme.bodyMedium,
            ),
          ),
          SizedBox(
            width: 60,
            child: Center(
              child: Switch.adaptive(
                value: pref.inApp,
                onChanged: (v) => onChanged(v, pref.push),
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Center(
              child: Switch.adaptive(
                value: pref.push,
                onChanged: (v) => onChanged(pref.inApp, v),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
