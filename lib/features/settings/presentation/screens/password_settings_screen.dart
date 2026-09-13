import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../../shared/widgets/mouj_tech_brand.dart';
import '../../../auth/domain/password_validation.dart';

/// Settings → Password & Security.
///
/// Always shows the SAME initial state regardless of
/// AuthProvider.currentUser.hasPassword — Current Password field, Verify
/// button, "Forgot password?" underneath. There is no separate "Set
/// Password with OTP" screen shown up front for a has_password=false
/// account: that would be a password-setup screen appearing BEFORE any
/// current-password verification, which is exactly what must never
/// happen here. The header body text is the only thing that varies with
/// hasPassword ("Your password is set." vs. "You haven't set a password
/// yet.") — a has_password=false account simply can never successfully
/// verify a current password (there isn't one), so it's steered to
/// "Forgot password?" instead, not blocked from seeing the same screen.
///
/// Two entirely separate paths from here, per spec — never merged:
///
///   A. Update Password (current password known): Current Password
///      verified FIRST (its own standalone step, no side effects) ->
///      only on success, New Password + Confirm New Password appear ->
///      Change Password calls the backend change-password endpoint
///      directly (current password re-proven server-side) -> back to
///      Settings. NEVER sends an OTP.
///
///   B. Forgot password (no current password, or it's simply forgotten):
///      uses the ALREADY-authenticated account's own email/phone — never
///      re-asks for an identifier — sends OTP -> OTP verified ->
///      New Password + Confirm New Password (SetPasswordScreen) ->
///      change-password -> back to Settings. This is the ONLY path here
///      that ever sends an OTP, and it's the one and only way a
///      has_password=false account ever establishes its first password
///      from Settings.
class PasswordSettingsScreen extends StatefulWidget {
  const PasswordSettingsScreen({super.key});

  @override
  State<PasswordSettingsScreen> createState() => _PasswordSettingsScreenState();
}

class _PasswordSettingsScreenState extends State<PasswordSettingsScreen> {
  final _currentFormKey = GlobalKey<FormState>();
  final _newFormKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isStartingRecovery = false;

  // Step 1 (current-password proof) is complete once this is true — only
  // then does step 2 (new password + confirm) render at all.
  bool _currentPasswordVerified = false;
  String? _currentPasswordError;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyCurrentPassword() async {
    if (!(_currentFormKey.currentState?.validate() ?? false)) return;
    setState(() => _currentPasswordError = null);

    final auth = context.read<AuthProvider>();
    final result = await auth.verifyCurrentPassword(_currentCtrl.text);

    if (!mounted) return;
    if (result.success) {
      setState(() => _currentPasswordVerified = true);
    } else {
      // Stop here, show an error, never send an OTP, never reveal the
      // new-password fields, never change anything. A has_password=false
      // account always ends up here too (there's no real password to
      // match), which is exactly the expected/correct behavior — the
      // error message doesn't need to special-case it since "Forgot
      // password?" is right there either way.
      setState(() {
        _currentPasswordError =
            result.errorMessage ?? context.l10n.authInvalidCredentials;
      });
    }
  }

  /// Current password already proven in the step above — no OTP, no
  /// re-authentication, just the backend change-password endpoint (which
  /// re-verifies the current password itself server-side; see
  /// AuthRepository.changePassword's own doc). Returns to Settings on
  /// success, exactly per spec — never Home, never Login.
  Future<void> _submitNewPassword() async {
    if (!(_newFormKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    final result = await auth.changePassword(
      _currentCtrl.text,
      _newCtrl.text,
      _confirmCtrl.text,
    );

    if (!mounted) return;
    if (result.success) {
      context.showSnackBar(context.l10n.passwordSettingsChangeSuccess);
      context.go(RouteNames.settings);
    } else {
      context.showErrorSnackBar(
        result.errorMessage ?? context.l10n.errorUnexpected,
      );
    }
  }

  /// "Forgot password?" — the ONLY OTP path this screen offers, and
  /// completely separate from Update Password above. Uses the
  /// already-authenticated account's own email/phone (never re-asks for
  /// an identifier), sends OTP, then hands off to OtpScreen with
  /// isPasswordRecovery + returnToSettingsOnSuccess both true so the
  /// resulting SetPasswordScreen returns here — never Home, never
  /// onboarding — once the new password is set. Works identically
  /// whether this account already has a password (replaces it) or never
  /// had one (establishes its first) — has_password plays no role in
  /// which path this takes, only in what happens if the user instead
  /// tries the current-password step above.
  Future<void> _startForgotPasswordRecovery() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    final auth = context.read<AuthProvider>();
    setState(() => _isStartingRecovery = true);

    final phoneNumber = user.phoneNumber;
    final isPhoneAccount = phoneNumber != null && phoneNumber.isNotEmpty;

    bool success;
    String? errorMessage;
    String otpIdentifier;

    if (isPhoneAccount) {
      final result = await auth.sendPhoneOtp(phoneNumber);
      success = result.success;
      errorMessage = result.errorMessage;
      otpIdentifier = result.syntheticEmail ?? '';
    } else {
      final result = await auth.sendOtp(user.email);
      success = result.success;
      errorMessage = result.errorMessage;
      otpIdentifier = user.email;
    }

    if (!mounted) return;
    setState(() => _isStartingRecovery = false);

    if (success) {
      context.push(
        RouteNames.authOtp,
        extra: (
          identifier: otpIdentifier,
          phoneNumber: isPhoneAccount ? phoneNumber : null,
          isPasswordRecovery: true,
          pendingPassword: null,
          returnToSettingsOnSuccess: true,
        ),
      );
    } else {
      context.showErrorSnackBar(errorMessage ?? context.l10n.errorUnexpected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final hasPassword =
        context.watch<AuthProvider>().currentUser?.hasPassword ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.passwordSettingsTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.passwordSettingsNoPasswordTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasPassword
                    ? l10n.passwordSettingsHasPasswordBody
                    : l10n.passwordSettingsNoPasswordBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _currentPasswordVerified
                    ? _buildNewPasswordStep(context)
                    : _buildCurrentPasswordStep(context),
              ),

              const MoujTechBrand(size: MoujTechBrandSize.compact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPasswordStep(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _currentFormKey,
      child: Column(
        key: const ValueKey('current-password-step'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _currentCtrl,
            obscureText: _obscureCurrent,
            autofillHints: const [AutofillHints.password],
            onChanged: (_) {
              if (_currentPasswordError != null) {
                setState(() => _currentPasswordError = null);
              }
            },
            decoration: InputDecoration(
              labelText: l10n.passwordSettingsCurrentLabel,
              prefixIcon: const Icon(Icons.lock_outline),
              errorText: _currentPasswordError,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrent
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: _obscureCurrent
                    ? l10n.authShowPassword
                    : l10n.authHidePassword,
                onPressed: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
            validator: (v) =>
                (v ?? '').isEmpty ? l10n.authPasswordRequired : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: _isStartingRecovery
                  ? null
                  : _startForgotPasswordRecovery,
              child: _isStartingRecovery
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colorScheme.primary,
                      ),
                    )
                  : Text(l10n.authForgotPassword),
            ),
          ),
          const SizedBox(height: 8),
          Consumer<AuthProvider>(
            builder: (_, auth, __) => JButton(
              label: l10n.passwordSettingsVerifyButton,
              onPressed: _verifyCurrentPassword,
              isLoading: auth.isVerifyingCurrentPassword,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPasswordStep(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _newFormKey,
      child: Column(
        key: const ValueKey('new-password-step'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _newCtrl,
            obscureText: _obscureNew,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: l10n.passwordSettingsNewLabel,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: _obscureNew
                    ? l10n.authShowPassword
                    : l10n.authHidePassword,
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            validator: (v) => validatePasswordFormat(v, l10n),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: l10n.passwordSettingsConfirmLabel,
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
            validator: (v) =>
                validatePasswordConfirmation(v, _newCtrl.text, l10n),
          ),
          const SizedBox(height: 20),

          Consumer<AuthProvider>(
            builder: (_, auth, __) => JButton(
              label: l10n.passwordSettingsChangeButton,
              onPressed: _submitNewPassword,
              isLoading: auth.isChangingPassword,
            ),
          ),
        ],
      ),
    );
  }
}
