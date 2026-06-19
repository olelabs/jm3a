import 'package:flutter/material.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';

// ── Review sheet ──────────────────────────────────────────────────────────────

class ReviewSheet extends StatefulWidget {
  const ReviewSheet({
    super.key,
    required this.packId,
    this.myRating,
    required this.onSubmit,
  });

  final String  packId;
  final int?    myRating;
  final Future<void> Function(String content, int? rating) onSubmit;

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  final _ctrl = TextEditingController();
  int  _rating = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.myRating ?? 0;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      decoration: BoxDecoration(
        color:        theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color:        theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          Text('Write a review',
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),

          // Star rating
          Row(
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => _rating = i + 1),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 36,
                  color: AppColors.amberOrangeLight,
                ),
              ),
            )),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _ctrl,
            maxLength: 500,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Share your thoughts about this pack…',
              counterText: '',
            ),
          ),
          const SizedBox(height: 20),

          JButton(
            label:     'Submit Review',
            isLoading: _isSubmitting,
            onPressed: () async {
              final text = _ctrl.text.trim();
              if (text.length < 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please write at least 10 characters.')),
                );
                return;
              }
              setState(() => _isSubmitting = true);
              await widget.onSubmit(text, _rating > 0 ? _rating : null);
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// ── Report sheet ──────────────────────────────────────────────────────────────

class ReportPackSheet extends StatefulWidget {
  const ReportPackSheet({
    super.key,
    required this.packId,
    required this.onSubmit,
  });

  final String  packId;
  final Future<void> Function(String reason, String? details) onSubmit;

  @override
  State<ReportPackSheet> createState() => _ReportPackSheetState();
}

class _ReportPackSheetState extends State<ReportPackSheet> {
  String? _reason;
  final _detailsCtrl = TextEditingController();
  bool _isSubmitting = false;

  static const _reasons = [
    ('spam',                 'Spam'),
    ('inappropriate_content', 'Inappropriate content'),
    ('hate_speech',          'Hate speech'),
    ('cheating',             'Cheating or gaming the system'),
    ('other',                'Other'),
  ];

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      decoration: BoxDecoration(
        color:        theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color:        theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          Text('Report pack',
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700, color: AppColors.errorRed)),
          const SizedBox(height: 8),
          Text('Help us keep the marketplace safe.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),

          ..._reasons.map((r) => RadioListTile<String>(
            title: Text(r.$2),
            value: r.$1,
            groupValue: _reason,
            onChanged: (v) => setState(() => _reason = v),
            dense: true,
            contentPadding: EdgeInsets.zero,
          )),

          const SizedBox(height: 8),

          TextField(
            controller: _detailsCtrl,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Additional details (optional)',
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),

          JButton(
            label:      'Submit Report',
            isLoading:  _isSubmitting,
            isDestructive: true,
            onPressed: _reason == null ? null : () async {
              setState(() => _isSubmitting = true);
              await widget.onSubmit(
                _reason!, _detailsCtrl.text.trim().isEmpty
                    ? null : _detailsCtrl.text.trim());
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// ── Rating widget ─────────────────────────────────────────────────────────────

class PackRatingWidget extends StatefulWidget {
  const PackRatingWidget({
    super.key,
    required this.packId,
    required this.myRating,
    required this.onRated,
  });

  final String packId;
  final int    myRating;
  final Future<void> Function(int rating) onRated;

  @override
  State<PackRatingWidget> createState() => _PackRatingWidgetState();
}

class _PackRatingWidgetState extends State<PackRatingWidget> {
  late int _hover;
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.myRating;
    _hover    = widget.myRating;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your rating:',
            style: context.textTheme.labelLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Row(
          children: List.generate(5, (i) {
            final filled = i < _hover;
            return GestureDetector(
              onTap: () async {
                setState(() => _selected = i + 1);
                await widget.onRated(i + 1);
              },
              child: MouseRegion(
                onEnter: (_) => setState(() => _hover = i + 1),
                onExit:  (_) => setState(() => _hover = _selected),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 32,
                    color: AppColors.amberOrangeLight,
                  ),
                ),
              ),
            );
          }),
        ),
        if (_selected > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('You rated this $_selected/5',
                style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant)),
          ),
      ],
    );
  }
}
