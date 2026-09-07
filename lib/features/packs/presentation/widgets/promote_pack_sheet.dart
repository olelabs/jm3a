import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/platform_config_provider.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../data/pack_repository.dart';

/// Lets a verified creator promote one of their published packs for a
/// chosen duration. Pops `true` on success so the caller can show a
/// confirmation snackbar. Pricing is loaded from app_settings, never
/// hardcoded — mirrors [PhysicalPackRequestSheet]'s structure.
class PromotePackSheet extends StatefulWidget {
  const PromotePackSheet({super.key, required this.packId});
  final String packId;

  @override
  State<PromotePackSheet> createState() => _PromotePackSheetState();
}

class _PromotePackSheetState extends State<PromotePackSheet> {
  Map<String, int> _prices = const {'24h': 0, '7d': 0};
  bool _loadingPrices = true;
  String _duration = '24h';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  // Reads through the app's single centralized app_settings cache
  // (PlatformConfigProvider) instead of this sheet querying app_settings
  // on its own — forces a refresh first if nothing has loaded yet (e.g.
  // this sheet opened before the app's initial config fetch finished).
  Future<void> _loadPrices() async {
    final config = context.read<PlatformConfigProvider>();
    if (!config.hasLoadedOnce) {
      await config.refresh();
    }
    if (mounted) {
      setState(() {
        _prices = {
          '24h': config.packPromotionPrice24hMru,
          '7d': config.packPromotionPrice7dMru,
        };
        _loadingPrices = false;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await PackRepository.instance.promotePack(
        packId: widget.packId,
        duration: _duration,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Failure catch (e) {
      setState(() => _submitting = false);
      if (mounted) context.showErrorSnackBar(e.message);
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) context.showErrorSnackBar(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                context.l10n.packPromoteYourPack,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.packPromotionSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              if (_loadingPrices)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Column(
                  children: [
                    _DurationTile(
                      label: context.l10n.packPromotionDuration24h,
                      priceMru: _prices['24h'] ?? 0,
                      selected: _duration == '24h',
                      onTap: () => setState(() => _duration = '24h'),
                    ),
                    const SizedBox(height: 10),
                    _DurationTile(
                      label: context.l10n.packPromotionDuration7d,
                      priceMru: _prices['7d'] ?? 0,
                      selected: _duration == '7d',
                      onTap: () => setState(() => _duration = '7d'),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting || _loadingPrices ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.l10n.packPromotionSubmit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationTile extends StatelessWidget {
  const _DurationTile({
    required this.label,
    required this.priceMru,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int priceMru;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Text(
              '$priceMru MRU',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
