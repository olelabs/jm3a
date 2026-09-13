import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/platform_config_provider.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../wallet_provider.dart';
import '../widgets/payment_method_card.dart';
import 'transaction_status_screen.dart';

/// Deposit flow — 3 steps:
///   1. Select payment method
///   2. Enter amount + phone + reference
///   3. Confirmation / status
class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  int _step = 0;
  PaymentMethodEntity? _selectedMethod;

  final _amountCtrl    = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _formKey       = GlobalKey<FormState>();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _phoneCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  int get _parsedAmount =>
      int.tryParse(_amountCtrl.text.replaceAll(',', '').trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    // §11: deposits_enabled — server-side (a BEFORE INSERT trigger on
    // `deposits`) is the real enforcement; this is presentation-only, so a
    // disabled admin toggle shows a clear unavailable state up front
    // instead of only failing after the user fills the whole form in.
    if (!context.watch<PlatformConfigProvider>().depositsEnabled) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.walletDeposit)),
        body: ErrorView(message: context.l10n.walletDepositsUnavailable),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.walletDeposit),
        bottom: _step > 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: _step / 2,
                  backgroundColor:
                      context.colorScheme.surfaceContainerHighest,
                ),
              )
            : null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey(_step),
          child: switch (_step) {
            0 => _MethodSelectionStep(
                methods:    context.watch<WalletProvider>().depositMethods,
                loaded:     context.watch<WalletProvider>().paymentMethodsLoaded,
                onSelected: (m) =>
                    setState(() { _selectedMethod = m; _step = 1; }),
              ),
            _ => _AmountStep(
                method:         _selectedMethod!,
                amountCtrl:     _amountCtrl,
                phoneCtrl:      _phoneCtrl,
                referenceCtrl:  _referenceCtrl,
                formKey:        _formKey,
                isSubmitting:   _isSubmitting,
                onBack:         () => setState(() => _step = 0),
                onSubmit:       _submit,
              ),
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    final result = await context.read<WalletProvider>().requestDeposit(
      amountMru:         _parsedAmount,
      paymentMethodId:   _selectedMethod!.id,
      phoneNumber:       _phoneCtrl.text.trim(),
      paymentReference:  _referenceCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionStatusScreen(
            isSuccess:   true,
            title:       context.l10n.walletDepositSubmittedTitle,
            subtitle:    context.l10n.walletDepositSubmittedSubtitle(
              result.deposit?.formattedAmount(context.l10n.walletCurrencyShort) ?? '',
            ),
            icon:        Icons.hourglass_top_rounded,
            iconColor:   AppColors.warningAmber,
          ),
        ),
      );
    } else {
      context.showErrorSnackBar(
        result.error ?? context.l10n.walletDepositRequestFailed,
      );
    }
  }
}

// ── Step 1: Payment method selection ─────────────────────────────────────────
class _MethodSelectionStep extends StatelessWidget {
  const _MethodSelectionStep({
    required this.methods,
    required this.loaded,
    required this.onSelected,
  });
  final List<PaymentMethodEntity> methods;
  final bool loaded;
  final void Function(PaymentMethodEntity) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.walletSelectPaymentMethod,
              style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700))
              .animate().fadeIn(),
          const SizedBox(height: 6),
          Text(context.l10n.walletChooseHowToAddFunds,
              style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant))
              .animate(delay: 40.ms).fadeIn(),
          const SizedBox(height: 24),

          if (methods.isEmpty && !loaded)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (methods.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  context.l10n.walletFinanceServiceUnavailable,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ...methods.asMap().entries.map((e) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PaymentMethodCard(
                    method:  e.value,
                    onTap:   () => onSelected(e.value),
                    showArrow: true,
                  ).animate(delay: (e.key * 40).ms).fadeIn()
                      .slideX(begin: 0.04, end: 0),
                )),
        ],
      ),
    );
  }
}

// ── Step 2: Amount + reference ────────────────────────────────────────────────
class _AmountStep extends StatefulWidget {
  const _AmountStep({
    required this.method,
    required this.amountCtrl,
    required this.phoneCtrl,
    required this.referenceCtrl,
    required this.formKey,
    required this.isSubmitting,
    required this.onBack,
    required this.onSubmit,
  });

  final PaymentMethodEntity       method;
  final TextEditingController     amountCtrl;
  final TextEditingController     phoneCtrl;
  final TextEditingController     referenceCtrl;
  final GlobalKey<FormState>      formKey;
  final bool                      isSubmitting;
  final VoidCallback              onBack;
  final VoidCallback              onSubmit;

  @override
  State<_AmountStep> createState() => _AmountStepState();
}

class _AmountStepState extends State<_AmountStep> {
  int get _amount =>
      int.tryParse(widget.amountCtrl.text.replaceAll(',', '').trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected method chip
            PaymentMethodCard(method: widget.method, compact: true)
                .animate().fadeIn(),
            const SizedBox(height: 24),

            // Instructions
            if (widget.method.instructions != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:        AppColors.infoBlue.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.infoBlue.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.infoBlue, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.method.instructions!,
                          style: const TextStyle(fontSize: 13, height: 1.5)),
                    ),
                  ],
                ),
              ).animate(delay: 40.ms).fadeIn(),
              const SizedBox(height: 20),
            ],

            // Account info
            if (widget.method.accountNumber != null) ...[
              _InfoRow(label: context.l10n.accountLabel, value: widget.method.accountNumber!),
              if (widget.method.accountName != null)
                _InfoRow(label: context.l10n.nameLabel, value: widget.method.accountName!),
              const SizedBox(height: 20),
            ],

            // Amount input
            Text(context.l10n.walletTransferAmount,
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.amountCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText:   '0',
                suffixText: context.l10n.walletCurrencyShort,
                prefixIcon: const Icon(Icons.money_rounded),
                helperText: _amount > 0
                    ? context.l10n.walletAmountValue(_amount.toString())
                    : null,
              ),
              validator: (v) {
                final n = int.tryParse(v?.replaceAll(',', '') ?? '0') ?? 0;
                if (n < 100)  return context.l10n.walletMinDeposit;
                if (n > 1_000_000) return context.l10n.walletMaxDeposit;
                return null;
              },
            ).animate(delay: 80.ms).fadeIn(),
            const SizedBox(height: 16),

            // Phone number
            Text(context.l10n.walletYourPhoneNumber,
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.phoneCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              // Exactly 8 digits, digits only — mirrors jma3a-api's
              // authoritative server-side check exactly (task section 2),
              // never stricter or looser.
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
              decoration: InputDecoration(
                hintText:   context.l10n.walletPhoneNumberHint,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                if (!RegExp(r'^\d{8}$').hasMatch(v?.trim() ?? '')) return context.l10n.phoneInvalid;
                return null;
              },
            ).animate(delay: 100.ms).fadeIn(),
            const SizedBox(height: 16),

            // Payment reference
            Text(context.l10n.walletPaymentReferenceLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.referenceCtrl,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              // Configured per payment method (payment_methods_config.
              // payment_reference_max_length, task section 3) — never
              // silently truncates; the field simply refuses further
              // input once the limit is reached (standard maxLength
              // behavior), and jma3a-api enforces the same limit
              // authoritatively regardless of what the client allowed.
              maxLength: widget.method.paymentReferenceMaxLength ?? 100,
              decoration: InputDecoration(
                hintText:   context.l10n.walletReferenceHint,
                prefixIcon: const Icon(Icons.receipt_outlined),
              ),
              validator: (v) {
                if ((v?.trim() ?? '').length < 3) {
                  return context.l10n.walletEnterReference;
                }
                return null;
              },
            ).animate(delay: 120.ms).fadeIn(),

            const SizedBox(height: 28),

            // Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningAmber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.warningAmber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.walletDepositWarningNotice,
                      style: const TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 140.ms).fadeIn(),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    child: Text(context.l10n.back),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: JButton(
                    label:     context.l10n.walletSubmitDeposit,
                    onPressed: widget.onSubmit,
                    isLoading: widget.isSubmitting,
                    icon:      Icons.send_rounded,
                  ),
                ),
              ],
            ).animate(delay: 160.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(context.l10n.labelColonSuffix(label),
              style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant)),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              context.showSnackBar(context.l10n.copiedNotice);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value,
                    style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                const Icon(Icons.copy_rounded,
                    size: 12, color: AppColors.infoBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
