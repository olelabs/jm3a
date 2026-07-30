import 'package:flutter/material.dart';

import '../../../../shared/widgets/feedback/error_view.dart';
import '../../data/pack_repository.dart';

/// Read-only status list of the caller's own physical pack requests —
/// scoped server-side by RLS, never shows another user's requests.
class PhysicalPackRequestsScreen extends StatefulWidget {
  const PhysicalPackRequestsScreen({super.key});

  @override
  State<PhysicalPackRequestsScreen> createState() =>
      _PhysicalPackRequestsScreenState();
}

class _PhysicalPackRequestsScreenState
    extends State<PhysicalPackRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await PackRepository.instance.getMyPhysicalPackRequests();
      if (mounted)
        setState(() {
          _requests = rows;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = '$e';
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Physical Pack Requests')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ErrorView(message: _error!, onRetry: _load)
            : _requests.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No requests yet.')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final r = _requests[i];
                  final pack = r['packs'] as Map<String, dynamic>?;
                  final title =
                      (pack?['title'] as Map<String, dynamic>?)?['en']
                          as String? ??
                      'Pack';
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${r['price_mru']} MRU · ${r['city']}, ${r['country']}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _RequestTimeline(request: r),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// Vertical stepper: each entry is (status value, label, timestamp column).
/// Adding a real shipping-provider integration later only ever means adding
/// a new entry here — the widget below is generic over this list.
const _kStages = [
  ('pending', 'Request Submitted', 'created_at'),
  ('payment_confirmed', 'Payment Confirmed', 'payment_confirmed_at'),
  ('under_review', 'Under Review', 'under_review_at'),
  ('printing', 'Printing', 'printing_at'),
  ('packaging', 'Packaging', 'packaging_at'),
  ('out_for_delivery', 'Out for Delivery', 'out_for_delivery_at'),
  ('delivered', 'Delivered', 'delivered_at'),
  ('completed', 'Completed', 'completed_at'),
];

class _RequestTimeline extends StatelessWidget {
  const _RequestTimeline({required this.request});
  final Map<String, dynamic> request;

  DateTime? _ts(String column) {
    final raw = request[column] as String?;
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  String _formatTs(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = request['status'] as String? ?? 'pending';

    if (status == 'cancelled') {
      final cancelledAt = _ts('cancelled_at');
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel_outlined, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                cancelledAt != null
                    ? 'Cancelled on ${_formatTs(cancelledAt)}'
                    : 'Cancelled',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      );
    }

    // A request created before this timeline existed may have jumped
    // straight from 'pending' to a legacy 'processing'/'shipped' value —
    // treat those as "under_review" / "out_for_delivery" so old rows still
    // render a sensible position instead of looking stuck at step 1.
    final effectiveStatus = switch (status) {
      'processing' => 'under_review',
      'shipped' => 'out_for_delivery',
      _ => status,
    };
    final currentIndex = _kStages.indexWhere(
      (s) => s.$1 == effectiveStatus,
    ).clamp(0, _kStages.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _kStages.length; i++)
          _StageRow(
            label: _kStages[i].$2,
            timestamp: _ts(_kStages[i].$3),
            isDone: i < currentIndex,
            isCurrent: i == currentIndex,
            isLast: i == _kStages.length - 1,
          ),
      ],
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.label,
    required this.timestamp,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });
  final String label;
  final DateTime? timestamp;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  String _formatTs(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reached = isDone || isCurrent;
    final color = isCurrent
        ? theme.colorScheme.primary
        : isDone
        ? theme.colorScheme.primary.withOpacity(0.6)
        : theme.colorScheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                isDone
                    ? Icons.check_circle
                    : isCurrent
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: color,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: isDone
                        ? theme.colorScheme.primary.withOpacity(0.4)
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: reached
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (timestamp != null)
                    Text(
                      _formatTs(timestamp!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
