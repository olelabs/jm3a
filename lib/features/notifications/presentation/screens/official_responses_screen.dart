import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../shared/widgets/cards/official_response_tile.dart';
import '../../../../shared/widgets/cards/user_request_tile.dart';
import '../../../../shared/widgets/overlays/confirm_dialog.dart';
import '../../../profile/data/profile_repository.dart';
import '../../domain/official_response_category.dart';
import '../../domain/user_request_entity.dart';
import '../notification_provider.dart';

/// Item 3 of the audit — "Jma3a / Official Responses": a dedicated,
/// user-facing place to see official moderation/review decisions
/// concerning the viewing user (pack reviews, warnings, bans/suspensions,
/// creator-verification/report decisions). Built entirely as a filtered,
/// categorized read view over the EXISTING NotificationProvider/
/// `notifications` table — no second notification system. Privacy is
/// enforced by `notifications`' own RLS (`auth.uid() = user_id`), which
/// NotificationProvider already relies on for every other screen; this
/// screen adds no new query surface, only a client-side category filter
/// over data the user could already see in the general Notifications list.
class OfficialResponsesScreen extends StatefulWidget {
  const OfficialResponsesScreen({super.key});

  @override
  State<OfficialResponsesScreen> createState() =>
      _OfficialResponsesScreenState();
}

class _OfficialResponsesScreenState extends State<OfficialResponsesScreen>
    with SingleTickerProviderStateMixin {
  // "My Requests" leads, then the four official-response categories: what
  // the user themselves asked for is the thing they came looking for, and
  // the official decisions follow. +1 rather than a fifth enum value —
  // OfficialResponseCategory describes how a NOTIFICATION is bucketed, and
  // a submitted request is not a notification.
  late final TabController _tabController = TabController(
    length: OfficialResponseCategory.values.length + 1,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    // NotificationProvider is app-wide and already loaded for the badge
    // count/general Notifications screen — a light refresh here just
    // ensures this screen shows the latest state on direct navigation,
    // not a second/duplicate load path.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationProvider>().refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _categoryLabel(BuildContext context, OfficialResponseCategory c) =>
      switch (c) {
        OfficialResponseCategory.reviews => context.l10n.officialResponsesReviews,
        OfficialResponseCategory.warnings => context.l10n.officialResponsesWarnings,
        OfficialResponseCategory.bansAndSuspensions =>
          context.l10n.officialResponsesBansAndSuspensions,
        OfficialResponseCategory.requestsAndDecisions =>
          context.l10n.officialResponsesRequestsAndDecisions,
      };

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.officialResponsesTitle),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: context.l10n.myRequestsTab),
            ...OfficialResponseCategory.values.map(
              (c) => Tab(text: _categoryLabel(context, c)),
            ),
          ],
        ),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          final all = provider.notifications
              .where(isOfficialResponseNotification)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              MyRequestsTab(languageCode: lang),
              ...OfficialResponseCategory.values.map((category) {
                final items = all
                    .where((n) => officialResponseCategoryFor(n) == category)
                    .toList();
                return _CategoryList(
                  items: items,
                  languageCode: lang,
                  emptyLabel: context.l10n.officialResponsesEmpty,
                  onRefresh: provider.refresh,
                  onOpen: (n) => _open(context, provider, n),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  void _open(
    BuildContext context,
    NotificationProvider provider,
    NotificationEntity n,
  ) {
    if (!n.isRead) provider.markRead(n.id);
    // Related-object navigation (e.g. open the reviewed pack) is
    // intentionally left to whatever this notification's `data` already
    // carries (pack_id/target_id) once a concrete route is agreed for it —
    // this screen's own scope is showing the decision, not building new
    // navigation targets for every notification type.
  }
}

/// "My Requests" — everything this user has asked the Jma3a official/admin
/// side for, and where each request currently stands.
///
/// Reads [ProfileRepository.getMyRequests], which is a pure projection over
/// request tables the user could already read under their own RLS. Nothing
/// here writes, except the ONE cancellation the backend actually supports
/// (a still-pending account deletion), which reuses the existing
/// `cancelAccountDeletionRequest` RPC and the existing Settings
/// confirmation strings rather than introducing a second cancel path.
///
/// Public so a widget test can pump it without the enclosing screen's
/// NotificationProvider.
class MyRequestsTab extends StatefulWidget {
  const MyRequestsTab({super.key, required this.languageCode});

  final String languageCode;

  @override
  State<MyRequestsTab> createState() => _MyRequestsTabState();
}

class _MyRequestsTabState extends State<MyRequestsTab> {
  late Future<List<UserRequestEntity>> _future;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _future = ProfileRepository.instance.getMyRequests();
  }

  Future<void> _refresh() async {
    final future = ProfileRepository.instance.getMyRequests();
    setState(() => _future = future);
    await future.catchError((_) => <UserRequestEntity>[]);
  }

  Future<void> _cancelDeletion() async {
    if (_cancelling) return;
    final l10n = context.l10n;

    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.settingsCancelAccountDeletionDialogTitle,
      message: l10n.settingsCancelAccountDeletionDialogMessage,
      confirmLabel: l10n.settingsCancelAccountDeletionConfirm,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      final cancelled = await ProfileRepository.instance
          .cancelAccountDeletionRequest();
      if (!mounted) return;
      context.showSnackBar(
        cancelled
            ? l10n.settingsAccountDeletionCancelled
            : l10n.settingsCancelAccountDeletionFailed,
      );
    } catch (_) {
      if (mounted) {
        context.showErrorSnackBar(l10n.settingsCancelAccountDeletionFailed);
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
      // Re-read either way: the RPC returns false (rather than throwing)
      // when the request is no longer pending, so the real server state is
      // the only thing worth showing afterwards.
      if (mounted) await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserRequestEntity>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final message = snapshot.hasError
            ? context.l10n.myRequestsLoadFailed
            : context.l10n.myRequestsEmpty;
        final requests = snapshot.data ?? const <UserRequestEntity>[];

        if (requests.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Text(
                    message,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: requests.length,
            itemBuilder: (context, i) => UserRequestTile(
              request: requests[i],
              languageCode: widget.languageCode,
              // Offered only where the backend can genuinely act on it, and
              // never while a cancellation is already in flight.
              onCancel: requests[i].canCancel && !_cancelling
                  ? _cancelDeletion
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.items,
    required this.languageCode,
    required this.emptyLabel,
    required this.onRefresh,
    required this.onOpen,
  });

  final List<NotificationEntity> items;
  final String languageCode;
  final String emptyLabel;
  final Future<void> Function() onRefresh;
  final void Function(NotificationEntity) onOpen;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Center(
              child: Text(
                emptyLabel,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, i) => OfficialResponseTile(
          notification: items[i],
          languageCode: languageCode,
          onTap: () => onOpen(items[i]),
        ),
      ),
    );
  }
}
