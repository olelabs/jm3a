import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../../domain/pack_entity.dart';
import '../pack_provider.dart';
import 'create_pack_screen.dart';

/// Creator dashboard showing created packs + analytics summary.
class CreatorDashboardScreen extends StatefulWidget {
  const CreatorDashboardScreen({super.key});

  @override
  State<CreatorDashboardScreen> createState() => _CreatorDashboardScreenState();
}

class _CreatorDashboardScreenState extends State<CreatorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PackProvider>().loadCreatedPacks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Studio'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/creator/create-pack'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Pack'),
          ),
        ],
      ),
      body: Consumer<PackProvider>(
        builder: (ctx, packs, _) {
          if (packs.isLoading && packs.createdPacks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (packs.failure != null && packs.createdPacks.isEmpty) {
            return ErrorView(
              message: 'Failed to load your packs.',
              onRetry: packs.loadCreatedPacks,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Stats summary ──────────────────────────────────────────
              _StatsSummary(packs: packs.createdPacks),
              const SizedBox(height: 20),

              // ── Pack list ──────────────────────────────────────────────
              Row(
                children: [
                  Text(
                    'Your Packs',
                    style: ctx.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${packs.createdPacks.length} packs',
                    style: ctx.textTheme.bodySmall?.copyWith(
                      color: ctx.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (packs.createdPacks.isEmpty)
                _EmptyCreator(
                  onCreateTap: () => context.push('/creator/create-pack'),
                )
              else
                ...packs.createdPacks.asMap().entries.map(
                  (e) => _CreatorPackRow(pack: e.value)
                      .animate(delay: (e.key * 40).ms)
                      .fadeIn()
                      .slideX(begin: 0.04, end: 0),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatsSummary extends StatelessWidget {
  const _StatsSummary({required this.packs});
  final List<PackEntity> packs;

  @override
  Widget build(BuildContext context) {
    final approved = packs.where((p) => p.status.isPublished).length;
    final purchases = packs.fold(0, (s, p) => s + p.totalPurchases);
    final avgRating = packs.isEmpty
        ? 0.0
        : packs.map((p) => p.avgRating).reduce((a, b) => a + b) / packs.length;

    return Row(
      children: [
        _StatCard(label: 'Published', value: '$approved', icon: '📦'),
        const SizedBox(width: 12),
        _StatCard(label: 'Sales', value: '$purchases', icon: '💰'),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Avg Rating',
          value: avgRating.toStringAsFixed(1),
          icon: '⭐',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              value,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorPackRow extends StatelessWidget {
  const _CreatorPackRow({required this.pack});
  final PackEntity pack;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final status = pack.status;

    final (statusLabel, statusColor) = switch (status) {
      PackStatus.approved => ('Published', AppColors.successGreen),
      PackStatus.pendingReview => ('In Review', AppColors.warningAmber),
      PackStatus.draft => ('Draft', AppColors.infoBlue),
      PackStatus.rejected => ('Rejected', AppColors.errorRed),
      PackStatus.suspended => ('Suspended', AppColors.errorRed),
      _ => ('Archived', AppColors.textTertiaryLight),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: JCard(
        padding: const EdgeInsets.all(14),
        onTap: pack.status.isEditable
            ? () => context.push(
                '/creator/create-pack',
                extra: {'packId': pack.id, 'draft': pack},
              )
            : null,
        child: Row(
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 52,
                height: 52,
                child: pack.coverImageUrl != null
                    ? Image.network(pack.coverImageUrl!, fit: BoxFit.cover)
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Text('🎮', style: TextStyle(fontSize: 22)),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pack.titleFor('en'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatusBadge(label: statusLabel, color: statusColor),
                      const SizedBox(width: 8),
                      Text(
                        '${pack.cardCount} cards • '
                        '${pack.totalPurchases} sales',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (status == PackStatus.rejected &&
                      (pack.rejectionReason?.isNotEmpty ?? false))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Rejection reason: ${pack.rejectionReason}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.errorRed,
                        ),
                        maxLines: 2,
                      ),
                    ),
                ],
              ),
            ),

            // Rating
            if (status.isPublished && pack.avgRating > 0)
              Column(
                children: [
                  Text(
                    pack.avgRating.toStringAsFixed(1),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: AppColors.amberOrangeLight,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyCreator extends StatelessWidget {
  const _EmptyCreator({required this.onCreateTap});
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Text('🎨', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'No packs yet',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first pack and share it with the world.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Pack'),
          ),
        ],
      ),
    );
  }
}
