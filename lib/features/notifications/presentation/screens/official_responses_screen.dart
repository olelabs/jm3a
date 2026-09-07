import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../shared/widgets/cards/official_response_tile.dart';
import '../../domain/official_response_category.dart';
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
  late final TabController _tabController = TabController(
    length: OfficialResponseCategory.values.length,
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
          tabs: OfficialResponseCategory.values
              .map((c) => Tab(text: _categoryLabel(context, c)))
              .toList(),
        ),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          final all = provider.notifications
              .where(isOfficialResponseNotification)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: OfficialResponseCategory.values.map((category) {
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
            }).toList(),
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
