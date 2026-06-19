import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../../shared/widgets/cards/j_card.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposit'),
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
            title:       'Deposit Submitted!',
            subtitle:    'Your deposit of ${result.deposit?.formattedAmount} '
                'is under review. Balance will update once approved.',
            icon:        Icons.hourglass_top_rounded,
            iconColor:   AppColors.warningAmber,
          ),
        ),
      );
    } else {
      context.showErrorSnackBar(result.error ?? 'Deposit request failed.');
    }
  }
}

// ── Step 1: Payment method selection ─────────────────────────────────────────
class _MethodSelectionStep extends StatelessWidget {
  const _MethodSelectionStep({
    required this.methods,
    required this.onSelected,
  });
  final List<PaymentMethodEntity> methods;
  final void Function(PaymentMethodEntity) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select payment method',
              style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700))
              .animate().fadeIn(),
          const SizedBox(height: 6),
          Text('Choose how you want to add funds.',
              style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant))
              .animate(delay: 40.ms).fadeIn(),
          const SizedBox(height: 24),

          if (methods.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
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
              _InfoRow(label: 'Account', value: widget.method.accountNumber!),
              if (widget.method.accountName != null)
                _InfoRow(label: 'Name', value: widget.method.accountName!),
              const SizedBox(height: 20),
            ],

            // Amount input
            Text('Transfer amount',
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
                suffixText: 'MRU',
                prefixIcon: const Icon(Icons.money_rounded),
                helperText: _amount > 0
                    ? 'Amount: ${_amount.toString()} MRU'
                    : null,
              ),
              validator: (v) {
                final n = int.tryParse(v?.replaceAll(',', '') ?? '0') ?? 0;
                if (n < 100)  return 'Minimum deposit: 100 MRU';
                if (n > 1_000_000) return 'Maximum deposit: 1,000,000 MRU';
                return null;
              },
            ).animate(delay: 80.ms).fadeIn(),
            const SizedBox(height: 16),

            // Phone number
            Text('Your phone number',
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText:   '+222 XX XX XX XX',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                if ((v?.trim() ?? '').length < 8) return 'Enter a valid phone number';
                return null;
              },
            ).animate(delay: 100.ms).fadeIn(),
            const SizedBox(height: 16),

            // Payment reference
            Text('Payment reference / transaction ID',
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.referenceCtrl,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText:   'e.g. TXN123456789',
                prefixIcon: Icon(Icons.receipt_outlined),
              ),
              validator: (v) {
                if ((v?.trim() ?? '').length < 3) {
                  return 'Enter the reference from your payment';
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
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.warningAmber, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only submit after completing the transfer. '
                      'Deposits are manually reviewed and may take 1–24 hours.',
                      style: TextStyle(fontSize: 12, height: 1.5),
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
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: JButton(
                    label:     'Submit Deposit',
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
          Text('$label: ',
              style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant)),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              context.showSnackBar('Copied!');
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
