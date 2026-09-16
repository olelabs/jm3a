import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../features/packs/presentation/pack_provider.dart';
import '../buttons/j_button.dart';

/// Trial Packs — shown from any of the 3 game screens (ToD/NHIE/Meme) the
/// moment the owner's client is told (by the server-authoritative
/// try_consume_trial_card RPC — see PackRepository, GameProvider trial
/// hooks) that this trial-limited pack's card allowance is exhausted.
///
/// Reuses the EXISTING pack purchase mechanism end to end
/// (PackProvider.purchasePack -> PackRepository.purchasePack -> the
/// existing /v1/packs/purchase route/purchase_pack RPC) and the same
/// confirm-before-charging dialog pack_detail_screen.dart's own
/// `_purchase()` already uses (packConfirmPurchaseTitle/Body/Action) — no
/// second payment flow, no duplicated confirmation copy.
///
/// Not dismissible by tapping outside/swiping down — the trial-exhausted
/// player must make an explicit choice (purchase or end trial), matching
/// "do not immediately kick the user out" while also never leaving the
/// prompt in an ambiguous, accidentally-dismissed state.
///
/// Returns true only on a confirmed successful purchase (the caller
/// should treat the pack as owned and resume advancing from exactly where
/// play stopped — see e.g. TodGameProvider.ownerAdvanceTurn's own trial
/// gate). Returns false if the player chose "End Trial" or the sheet was
/// otherwise dismissed — the caller must NOT advance the game in that
/// case, staying at the trial-limit state.
Future<bool> showTrialLimitSheet(BuildContext context, PackEntity pack) async {
  final purchased = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    builder: (_) => _TrialLimitSheet(pack: pack),
  );
  return purchased ?? false;
}

class _TrialLimitSheet extends StatefulWidget {
  const _TrialLimitSheet({required this.pack});
  final PackEntity pack;

  @override
  State<_TrialLimitSheet> createState() => _TrialLimitSheetState();
}

class _TrialLimitSheetState extends State<_TrialLimitSheet> {
  bool _purchasing = false;

  Future<void> _purchase() async {
    if (_purchasing) return;

    // Same confirm-before-charging step every other purchase entry point
    // in the app uses (pack_detail_screen.dart's _purchase()) — not a
    // second confirmation UX, the identical one, reused.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(dCtx.l10n.packConfirmPurchaseTitle),
        content: Text(
          dCtx.l10n.packConfirmPurchaseBody(
            widget.pack.titleFor(Localizations.localeOf(dCtx).languageCode),
            widget.pack.isFree
                ? dCtx.l10n.packFreeLabel
                : dCtx.l10n.packPriceMru(widget.pack.priceMru),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text(dCtx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text(dCtx.l10n.packConfirmPurchaseAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _purchasing = true);
    final error = await context.read<PackProvider>().purchasePack(widget.pack);
    if (!mounted) return;

    if (error == null) {
      // Success — close the sheet with `true`. The caller (game
      // provider) is what actually resumes play; this sheet has no game
      // state of its own to touch, matching "do not restart the game."
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _purchasing = false);
    context.showErrorSnackBar(
      error.toLowerCase().contains('insufficient')
          ? context.l10n.packInsufficientBalance
          : error,
    );
    // Stays open — failure/cancel never corrupts the trial-limit state,
    // the player can simply retry Purchase or tap End Trial.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.packTrialPromptTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.packTrialPromptBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            JButton(
              label: context.l10n.packTrialPurchaseButton,
              onPressed: _purchasing ? null : _purchase,
              isLoading: _purchasing,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _purchasing
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: Text(context.l10n.packTrialEndButton),
            ),
          ],
        ),
      ),
    );
  }
}
