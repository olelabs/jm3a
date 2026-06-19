import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';

/// Entry point for the auth flow.
/// Users enter their email to receive an OTP.
/// Also provides the guest mode path for offline-only play.
class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _emailFocus = FocusNode();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _emailFocus.unfocus();

    final email = _emailCtrl.text.trim().toLowerCase();
    final auth = context.read<AuthProvider>();
    final result = await auth.sendOtp(email);

    if (!mounted) return;
    if (result.success) {
      context.push(RouteNames.authOtp, extra: email);
    } else {
      context.showErrorSnackBar(
        result.errorMessage ?? context.l10n.errorUnexpected,
      );
    }
  }

  void _enterGuestMode() {
    context.read<AuthProvider>().enterGuestMode();
    context.go(RouteNames.offline);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 64),

                _BrandHeader()
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.15, end: 0),

                const SizedBox(height: 56),

                Text(
                  l10n.authWelcome,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0),

                const SizedBox(height: 8),

                Text(
                  l10n.authTagline,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ).animate(delay: 150.ms).fadeIn(),

                const SizedBox(height: 40),

                // Email field
                TextFormField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: l10n.authEmailLabel,
                    hintText: l10n.authEmailHint,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return l10n.authEmailInvalid;
                    if (!val.isValidEmail) return l10n.authEmailInvalid;
                    return null;
                  },
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.08, end: 0),

                const SizedBox(height: 24),

                // Send OTP button
                Consumer<AuthProvider>(
                  builder: (_, auth, __) => JButton(
                    label: l10n.authSendOtp,
                    onPressed: _submit,
                    isLoading: auth.isSendingOtp,
                  ),
                ).animate(delay: 280.ms).fadeIn(),

                const SizedBox(height: 20),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l10n.or,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ).animate(delay: 340.ms).fadeIn(),

                const SizedBox(height: 16),

                // Guest mode
                OutlinedButton.icon(
                  onPressed: _enterGuestMode,
                  icon: const Icon(Icons.person_outline_rounded, size: 20),
                  label: const Text('Continue as Guest'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ).animate(delay: 380.ms).fadeIn(),

                const SizedBox(height: 40),

                Center(
                  child: Text(
                    'By continuing you agree to our Terms & Privacy Policy',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate(delay: 420.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.navyBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.groups_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Jma3a',
          style: context.textTheme.titleLarge?.copyWith(
            color: AppColors.navyBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
