import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/buttons/j_button.dart';

/// Password recovery entry point: identifier → OTP → new password.
///
/// Reuses the exact same OTP send/verify machinery as normal sign-in
/// (sendOtp/sendPhoneOtp, then the existing OtpScreen) — the only
/// difference is the `isPasswordRecovery` flag threaded through so
/// OtpScreen routes to SetPasswordScreen afterward instead of letting the
/// router's normal post-login redirect take over (which would just send
/// this already-password-ready account straight to /home).
///
/// This is also the ONLY way a legacy account (has_password=false) ever
/// establishes its first password — there is no separate "legacy
/// account setup" flow; has_password=false is handled identically to a
/// forgotten password here.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.prefillIdentifier});

  /// Set when reached from the Login screen's "this account has no
  /// password yet" banner — pre-fills the identifier so the user doesn't
  /// have to retype what they just entered on Login.
  final String? prefillIdentifier;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefillIdentifier != null) {
      _identifierCtrl.text = widget.prefillIdentifier!;
    }
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final raw = _identifierCtrl.text.trim();
    final auth = context.read<AuthProvider>();
    setState(() => _isSubmitting = true);

    final isEmail = raw.contains('@');
    bool success;
    String? errorMessage;
    String identifier;
    String? phoneNumber;

    if (isEmail) {
      final email = raw.toLowerCase();
      final result = await auth.sendOtp(email);
      success = result.success;
      errorMessage = result.errorMessage;
      identifier = email;
    } else {
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      final phone = digits.startsWith('222') ? '+$digits' : '+222$digits';
      final result = await auth.sendPhoneOtp(phone);
      success = result.success;
      errorMessage = result.errorMessage;
      identifier = result.syntheticEmail ?? '';
      phoneNumber = phone;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      // go(), not push(): see LoginScreen._goToForgotPassword's own
      // comment — a stacked auth screen left underneath would get
      // revalidated by the router's global redirect the moment recovery
      // finishes, racing the explicit Set Password navigation.
      context.go(
        RouteNames.authOtp,
        extra: (
          identifier: identifier,
          phoneNumber: phoneNumber,
          isPasswordRecovery: true,
          pendingPassword: null,
          returnToSettingsOnSuccess: false,
        ),
      );
    } else {
      context.showErrorSnackBar(
        errorMessage ?? context.l10n.errorUnexpected,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.go(RouteNames.authPasswordLogin),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ).animate().fadeIn().slideY(begin: -0.1, end: 0),

                const SizedBox(height: 24),

                Text(
                  l10n.authForgotPasswordTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ).animate(delay: 80.ms).fadeIn(),

                const SizedBox(height: 8),

                Text(
                  l10n.authForgotPasswordSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ).animate(delay: 120.ms).fadeIn(),

                const SizedBox(height: 32),

                TextFormField(
                  controller: _identifierCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: l10n.authIdentifierLabel,
                    hintText: l10n.authIdentifierHint,
                    prefixIcon: const Icon(Icons.alternate_email),
                  ),
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) {
                      return l10n.authIdentifierRequired;
                    }
                    return null;
                  },
                ).animate(delay: 180.ms).fadeIn().slideY(begin: 0.08, end: 0),

                const SizedBox(height: 28),

                JButton(
                  label: l10n.authForgotPasswordSendCode,
                  onPressed: _submit,
                  isLoading: _isSubmitting,
                ).animate(delay: 240.ms).fadeIn(),

                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => context.go(RouteNames.authPasswordLogin),
                    child: Text(l10n.authBackToLogin),
                  ),
                ).animate(delay: 280.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
