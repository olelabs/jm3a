import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../domain/password_validation.dart';

/// Route arguments for [SetPasswordScreen]. [isRecovery] only changes the
/// copy shown. [returnToSettingsOnSuccess] distinguishes WHO started this
/// recovery — Login's Forgot Password (false: this account was not yet
/// authenticated, so success continues into onboarding/Home, same as any
/// other successful authentication) vs. Settings' Forgot Password
/// (true: the user was already authenticated and mid-Settings, so
/// success must return there — never Home, never onboarding, and never
/// re-asking for an identifier).
typedef SetPasswordScreenArgs = ({
  bool isRecovery,
  bool returnToSettingsOnSuccess,
});

/// Reached only from an explicitly-invoked flow — never a global router
/// redirect: the final step of password recovery/reset (after a recovery
/// OTP is verified — see OtpScreen's isPasswordRecovery navigation, from
/// either Login's or Settings' "Forgot password?"). New-signup collects
/// its password up front and applies it atomically inside OTP
/// verification (see SignupScreen and AuthProvider.verifyOtp's
/// pendingPassword), so it never passes through this screen at all.
class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({
    super.key,
    this.isRecovery = false,
    this.returnToSettingsOnSuccess = false,
  });

  final bool isRecovery;
  final bool returnToSettingsOnSuccess;

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    final result = await auth.setPassword(
      _passwordCtrl.text,
      _confirmCtrl.text,
    );

    if (!mounted) return;
    if (result.success) {
      context.showSnackBar(
        widget.isRecovery
            ? context.l10n.authPasswordResetSuccess
            : context.l10n.authPasswordSetSuccess,
      );
      if (widget.returnToSettingsOnSuccess) {
        // Settings' "Forgot password?" flow: the user was already
        // authenticated and mid-Settings before this started — return
        // there, never Home, never onboarding, never re-asking for an
        // identifier.
        context.go(RouteNames.passwordSettings);
      } else if (auth.needsOnboarding) {
        // A brand-new/incomplete account still needs profile setup right
        // after this — explicitly route there instead of always going
        // home, so it can't be skipped.
        context.go(RouteNames.onboarding);
      } else {
        context.go(RouteNames.home);
      }
    } else {
      context.showErrorSnackBar(
        result.errorMessage ?? context.l10n.errorUnexpected,
      );
    }
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
                const SizedBox(height: 48),

                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ).animate().fadeIn().slideY(begin: -0.1, end: 0),

                const SizedBox(height: 20),

                Text(
                  widget.isRecovery
                      ? l10n.authResetPasswordTitle
                      : l10n.authSetPasswordTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ).animate(delay: 80.ms).fadeIn(),

                const SizedBox(height: 8),

                Text(
                  widget.isRecovery
                      ? l10n.authResetPasswordSubtitle
                      : l10n.authSetPasswordSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ).animate(delay: 120.ms).fadeIn(),

                const SizedBox(height: 32),

                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: l10n.authPasswordLabel,
                    hintText: l10n.authPasswordHint,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      tooltip: _obscurePassword
                          ? l10n.authShowPassword
                          : l10n.authHidePassword,
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => validatePasswordFormat(v, l10n),
                ).animate(delay: 180.ms).fadeIn().slideY(begin: 0.08, end: 0),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: l10n.authPasswordConfirmationLabel,
                    hintText: l10n.authPasswordConfirmationHint,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      tooltip: _obscureConfirm
                          ? l10n.authShowPassword
                          : l10n.authHidePassword,
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passwordCtrl.text) return l10n.authPasswordMismatch;
                    return null;
                  },
                ).animate(delay: 220.ms).fadeIn().slideY(begin: 0.08, end: 0),

                const SizedBox(height: 28),

                Consumer<AuthProvider>(
                  builder: (_, auth, __) => JButton(
                    label: widget.isRecovery
                        ? l10n.authResetPasswordSubmit
                        : l10n.authSetPasswordSubmit,
                    onPressed: _submit,
                    isLoading: auth.isSettingPassword,
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
