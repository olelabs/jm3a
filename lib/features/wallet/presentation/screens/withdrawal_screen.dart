import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../wallet_provider.dart';
import '../widgets/payment_method_card.dart';
import 'transaction_status_screen.dart';

/// Withdrawal flow:
///   1. Select payout method
///   2. Enter amount + phone
///   3. Confirm & submit
class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  int _step = 0;
  PaymentMethodEntity? _selectedMethod;

  final _amountCtrl = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _formKey    = GlobalKey<FormState>();
  bool _isSubmitting = false;

  static const _minWithdrawal = 500;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  int get _parsedAmount =>
      int.tryParse(_amountCtrl.text.replaceAll(',', '').trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw'),
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
      body: Consumer<WalletProvider>(
        builder: (ctx, wallet, _) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey(_step),
              child: switch (_step) {
                0 => _MethodSelectionStep(
                    methods: wallet.withdrawMethods,
                    onSelected: (m) =>
                        setState(() { _selectedMethod = m; _step = 1; }),
                  ),
                1 => _AmountStep(
                    method:       _selectedMethod!,
                    wallet:       wallet,
                    amountCtrl:   _amountCtrl,
                    phoneCtrl:    _phoneCtrl,
                    formKey:      _formKey,
                    isSubmitting: _isSubmitting,
                    onBack:       () => setState(() => _step = 0),
                    onConfirm:    () => setState(() => _step = 2),
                  ),
                _ => _ConfirmStep(
                    method:       _selectedMethod!,
                    amountMru:    _parsedAmount,
                    phone:        _phoneCtrl.text.trim(),
                    wallet:       wallet,
                    isSubmitting: _isSubmitting,
                    onBack:       () => setState(() => _step = 1),
                    onSubmit:     _submit,
                  ),
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final result = await context.read<WalletProvider>().requestWithdrawal(
      amountMru:        _parsedAmount,
      paymentMethodId:  _selectedMethod!.id,
      phoneNumber:      _phoneCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionStatusScreen(
            isSuccess:   true,
            title:       'Withdrawal Submitted!',
            subtitle:    'Your withdrawal of ${result.withdrawal?.formattedAmount} '
                'is being processed. Funds will arrive within 1–24 hours.',
            icon:        Icons.schedule_rounded,
            iconColor:   AppColors.infoBlue,
          ),
        ),
      );
    } else {
      context.showErrorSnackBar(result.error ?? 'Withdrawal request failed.');
    }
  }
}

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
          Text('Select payout method',
              style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700))
              .animate().fadeIn(),
          const SizedBox(height: 24),
          if (methods.isEmpty)
            const Center(child: CircularProgressIndicator())
          else
            ...methods.asMap().entries.map((e) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PaymentMethodCard(
                    method:    e.value,
                    onTap:     () => onSelected(e.value),
                    showArrow: true,
                  ).animate(delay: (e.key * 40).ms).fadeIn(),
                )),
        ],
      ),
    );
  }
}

class _AmountStep extends StatefulWidget {
  const _AmountStep({
    required this.method,
    required this.wallet,
    required this.amountCtrl,
    required this.phoneCtrl,
    required this.formKey,
    required this.isSubmitting,
    required this.onBack,
    required this.onConfirm,
  });
  final PaymentMethodEntity   method;
  final WalletProvider        wallet;
  final TextEditingController amountCtrl;
  final TextEditingController phoneCtrl;
  final GlobalKey<FormState>  formKey;
  final bool                  isSubmitting;
  final VoidCallback          onBack;
  final VoidCallback          onConfirm;

  @override
  State<_AmountStep> createState() => _AmountStepState();
}

class _AmountStepState extends State<_AmountStep> {
  @override
  Widget build(BuildContext context) {
    // Withdrawals draw only from the earnings balance — never the
    // spendable wallet balance (deposits + transferred earnings).
    final balance = widget.wallet.earningsBalanceMru;
    final theme   = context.theme;

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
            PaymentMethodCard(method: widget.method, compact: true)
                .animate().fadeIn(),
            const SizedBox(height: 20),

            // Balance display
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, size: 18),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available earnings',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      Text(widget.wallet.formattedEarningsBalance,
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ).animate(delay: 40.ms).fadeIn(),

            const SizedBox(height: 20),

            Text('Amount to withdraw',
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.amountCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText:   '0',
                suffixText: 'MRU',
                prefixIcon: Icon(Icons.money_rounded),
              ),
              validator: (v) {
                final n = int.tryParse(v?.replaceAll(',', '') ?? '0') ?? 0;
                if (n < _WithdrawalScreen._minWithdrawal) {
                  return 'Minimum withdrawal: ${_WithdrawalScreen._minWithdrawal} MRU';
                }
                if (n > balance) return 'Insufficient balance';
                return null;
              },
            ).animate(delay: 80.ms).fadeIn(),

            // Quick amount buttons
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [500, 1000, 2000, 5000]
                  .where((a) => a <= balance)
                  .map((a) => ActionChip(
                        label: Text('$a MRU'),
                        onPressed: () => setState(() =>
                            widget.amountCtrl.text = a.toString()),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ).animate(delay: 100.ms).fadeIn(),

            const SizedBox(height: 16),

            Text('Payout phone number',
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText:   '+222 XX XX XX XX',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                if ((v?.trim() ?? '').length < 8) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ).animate(delay: 120.ms).fadeIn(),

            const SizedBox(height: 28),

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
                    label:     'Continue →',
                    onPressed: () {
                      if (widget.formKey.currentState?.validate() ?? false) {
                        widget.onConfirm();
                      }
                    },
                  ),
                ),
              ],
            ).animate(delay: 140.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

// Keep the min withdrawal constant accessible
extension _WithdrawalScreen on _AmountStepState {
  static const _minWithdrawal = 500;
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({
    required this.method,
    required this.amountMru,
    required this.phone,
    required this.wallet,
    required this.isSubmitting,
    required this.onBack,
    required this.onSubmit,
  });
  final PaymentMethodEntity method;
  final int                 amountMru;
  final String              phone;
  final WalletProvider      wallet;
  final bool                isSubmitting;
  final VoidCallback        onBack;
  final VoidCallback        onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme         = context.theme;
    final balanceAfter  = wallet.earningsBalanceMru - amountMru;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirm withdrawal',
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700))
              .animate().fadeIn(),
          const SizedBox(height: 24),

          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:        theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _ConfirmRow(label: 'Method',   value: method.name),
                _ConfirmRow(label: 'Phone',    value: phone),
                _ConfirmRow(label: 'Amount',
                    value: '$amountMru MRU',
                    valueStyle: TextStyle(
                        color:      AppColors.errorRed,
                        fontWeight: FontWeight.w800,
                        fontSize:   18)),
                const Divider(height: 24),
                _ConfirmRow(label: 'Balance after',
                    value: '$balanceAfter MRU',
                    valueStyle: TextStyle(
                        color: balanceAfter < 0
                            ? AppColors.errorRed
                            : AppColors.successGreen,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ).animate(delay: 40.ms).fadeIn(),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        AppColors.warningAmber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.warningAmber, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Withdrawals are processed manually. '
                    'Funds arrive in 1–24 hours once approved.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ).animate(delay: 80.ms).fadeIn(),

          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: JButton(
                  label:     'Confirm Withdrawal',
                  onPressed: onSubmit,
                  isLoading: isSubmitting,
                  isDestructive: false,
                  icon:      Icons.check_rounded,
                ),
              ),
            ],
          ).animate(delay: 120.ms).fadeIn(),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.label, required this.value, this.valueStyle});
  final String     label;
  final String     value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant)),
          Text(value,
              style: valueStyle ??
                  context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
