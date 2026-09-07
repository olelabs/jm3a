import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/platform_config_provider.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../../../../shared/widgets/media/signed_network_image.dart';
import '../../data/pack_repository.dart';
import '../pack_provider.dart';
import '../widgets/promote_pack_sheet.dart';

/// The pack's own title in the viewer's language if available, else in the
/// pack's declared language, else in whatever language it actually has —
/// [PackEntity.titleFor] never returns a raw id. Only truly empty title
/// data (a corrupt/incomplete pack row) falls through to the generic
/// localized "Pack" placeholder — never the pack's UUID.
String _displayTitle(BuildContext context, PackEntity pack) {
  final title = pack.titleFor(Localizations.localeOf(context).languageCode);
  return title.isNotEmpty ? title : context.l10n.defaultPackName;
}

/// Shared "+ New Pack" entry point for both the app-bar action and the
/// empty state below — the real one-draft-per-creator guarantee lives in
/// the database (idx_packs_one_draft_per_creator), so this pre-check is
/// purely a friendlier UX than always navigating in and only discovering
/// the block once the wizard tries to save (create_pack_screen.dart's
/// _saveDraft still handles that server 409 gracefully if this check is
/// stale or raced).
void _startCreatePack(BuildContext context) {
  if (context.read<PackProvider>().hasDraftPack) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.packDraftLimitReachedTitle),
        content: Text(ctx.l10n.packAlreadyHasDraft),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.ok),
          ),
        ],
      ),
    );
    return;
  }
  context.push('/creator/create-pack');
}

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
        title: Text(context.l10n.packCreatorStudio),
        actions: [
          TextButton.icon(
            onPressed: () => _startCreatePack(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(context.l10n.packNewPack),
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
              message: ctx.l10n.packFailedToLoadYourPacks,
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
                    ctx.l10n.packYourPacks,
                    style: ctx.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    ctx.l10n.packCountLabel(packs.createdPacks.length),
                    style: ctx.textTheme.bodySmall?.copyWith(
                      color: ctx.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (packs.createdPacks.isEmpty)
                _EmptyCreator(
                  onCreateTap: () => _startCreatePack(context),
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
        _StatCard(
          label: context.l10n.packStatPublished,
          value: '$approved',
          icon: '📦',
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: context.l10n.packStatSales,
          value: '$purchases',
          icon: '💰',
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: context.l10n.packStatAvgRating,
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

class _CreatorPackRow extends StatefulWidget {
  const _CreatorPackRow({required this.pack});
  final PackEntity pack;

  @override
  State<_CreatorPackRow> createState() => _CreatorPackRowState();
}

class _CreatorPackRowState extends State<_CreatorPackRow> {
  bool _deleting = false;
  PackPromotionStatus? _promotionStatus;

  @override
  void initState() {
    super.initState();
    if (widget.pack.status == PackStatus.approved) _loadPromotionStatus();
  }

  Future<void> _loadPromotionStatus() async {
    try {
      final status = await PackRepository.instance.getPackPromotionStatus(
        widget.pack.id,
      );
      if (mounted) setState(() => _promotionStatus = status);
    } catch (_) {
      // Best-effort UX hint only — promote_pack() itself is still the
      // authoritative check if this fails to load and the button shows.
    }
  }

  Future<void> _confirmDelete() async {
    final pack = widget.pack;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.packDeleteDraftConfirmTitle),
        content: Text(
          ctx.l10n.packDeleteDraftConfirmBody(_displayTitle(ctx, pack)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: Text(ctx.l10n.packDeleteDraft),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await PackRepository.instance.deletePackDraft(pack.id);
      if (!mounted) return;
      // Refresh from the server rather than just splicing the list
      // locally — matches how a successful submitForReview() already
      // refreshes createdPacks in create_pack_screen.dart, so this screen
      // has exactly one "the list changed, go re-fetch it" convention.
      await context.read<PackProvider>().loadCreatedPacks();
      if (!mounted) return;
      context.showSnackBar(context.l10n.packDraftDeletedNotice);
    } on Failure catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        context.showErrorSnackBar(
          context.l10n.packDeleteDraftFailed(e.message),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        context.showErrorSnackBar(
          context.l10n.packDeleteDraftFailed(e.toString()),
        );
      }
    }
  }

  /// Item 9/14/15 — promotion, reachable directly from the creator's own
  /// dashboard row (not only from the marketplace detail screen). Reuses
  /// the existing PromotePackSheet as-is (ownership/status/verification/
  /// price all re-verified server-side inside promote_pack() regardless
  /// of the fact this button is only ever shown for the creator's own
  /// approved pack) — this is presentation wiring, not a second
  /// promotion system.
  Future<void> _promote() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PromotePackSheet(packId: widget.pack.id),
    );
    if (result == true && mounted) {
      context.showSnackBar(context.l10n.packPromotionSuccess);
      _loadPromotionStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final pack = widget.pack;
    final status = pack.status;

    final (statusLabel, statusColor) = switch (status) {
      PackStatus.approved => (context.l10n.packStatusPublished, AppColors.successGreen),
      PackStatus.pendingReview => (context.l10n.packStatusInReview, AppColors.warningAmber),
      PackStatus.draft => (context.l10n.packStatusDraft, AppColors.infoBlue),
      PackStatus.rejected => (context.l10n.packStatusRejected, AppColors.errorRed),
      PackStatus.suspended => (context.l10n.packStatusSuspended, AppColors.errorRed),
      _ => (context.l10n.packStatusArchived, AppColors.textTertiaryLight),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: JCard(
        padding: const EdgeInsets.all(14),
        onTap: pack.isEditableByCreator
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
                    ? SignedNetworkImage(url: pack.coverImageUrl!, fit: BoxFit.cover)
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
                    _displayTitle(context, pack),
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
                        context.l10n.packCardsAndSales(
                          pack.cardCount,
                          pack.totalPurchases,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (pack.platformManaged)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _StatusBadge(
                        label: context.l10n.packPlatformManaged,
                        color: AppColors.warningAmber,
                      ),
                    ),
                  if (status == PackStatus.rejected &&
                      (pack.rejectionReason?.isNotEmpty ?? false))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        context.l10n.packRejectionReason(pack.rejectionReason ?? ''),
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

            // Delete draft — only ever shown for a pack still in draft;
            // once published for review (or beyond) this action disappears
            // and there is no other client-side way to remove the pack.
            if (status == PackStatus.draft)
              _deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: AppColors.errorRed,
                      tooltip: context.l10n.packDeleteDraft,
                      onPressed: _confirmDelete,
                    ),

            // Promote — item 9/14/15: only ever offered on the creator's
            // own approved/published pack, matching promote_pack()'s own
            // server-side "status = approved" gate exactly (drafts,
            // pending review, rejected packs never show this). Server is
            // still the source of truth for the already-active case —
            // promote_pack() itself now rejects a duplicate promotion
            // (already_promoted) even if this client-side status check
            // was stale or failed to load.
            if (status == PackStatus.approved &&
                (_promotionStatus?.active == true ||
                    context
                        .watch<PlatformConfigProvider>()
                        .packPromotionsEnabled))
              _promotionStatus?.active == true
                  ? Tooltip(
                      message: context.l10n.packPromotionEndsAt(
                        DateFormat.yMMMd(
                          Localizations.localeOf(context).toString(),
                        ).add_jm().format(_promotionStatus!.endsAt!.toLocal()),
                      ),
                      child: _StatusBadge(
                        label: context.l10n.packPromotionActiveLabel,
                        color: AppColors.brandPurpleMid,
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.trending_up_rounded),
                      color: AppColors.brandPurpleMid,
                      tooltip: context.l10n.packPromoteYourPack,
                      onPressed: _promote,
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
            context.l10n.packNoPacksYet,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.packCreateFirstHint,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add_rounded),
            label: Text(context.l10n.packCreatePack),
          ),
        ],
      ),
    );
  }
}
