import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../domain/password_validation.dart';
import '../widgets/auth_method_selector.dart';

/// Signup entry point for brand-new accounts only. Required order:
/// identifier -> password -> confirm -> check the account doesn't
/// already exist -> OTP -> verify -> account is password-ready
/// immediately. Password is validated and collected BEFORE any OTP is
/// ever sent; a signup can never bypass either password creation or OTP
/// verification. Normal login never routes through this screen (see
/// LoginScreen's "Create account" CTA, the only way in) — an existing
/// identifier is instead sent back to LoginScreen, prefilled.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inputCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _inputFocus = FocusNode();
  AuthMethod _method = AuthMethod.phone;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isCheckingAndSending = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _switchMethod(AuthMethod method) {
    if (method == _method) return;
    setState(() {
      _method = method;
      _inputCtrl.clear();
    });
    _formKey.currentState?.reset();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _inputFocus.unfocus();

    final auth = context.read<AuthProvider>();
    final password = _passwordCtrl.text;

    final String identifier;
    final String? phoneNumber;
    if (_method == AuthMethod.phone) {
      final digits = _inputCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
      identifier = '+222$digits';
      phoneNumber = identifier;
    } else {
      identifier = _inputCtrl.text.trim().toLowerCase();
      phoneNumber = null;
    }

    setState(() => _isCheckingAndSending = true);

    // Required order: identifier + password are already valid at this
    // point (form validation above) — now check the account doesn't
    // already exist BEFORE ever sending an OTP. A second account can
    // never be created for an identifier that's already registered.
    final existsResult = await auth.checkIdentifierExists(identifier);
    if (!mounted) return;

    if (!existsResult.success) {
      setState(() => _isCheckingAndSending = false);
      context.showErrorSnackBar(
        existsResult.errorMessage ?? context.l10n.errorUnexpected,
      );
      return;
    }

    if (existsResult.exists) {
      setState(() => _isCheckingAndSending = false);
      context.showSnackBar(context.l10n.authAccountAlreadyExists);
      context.pushReplacement(
        RouteNames.authPasswordLogin,
        extra: identifier,
      );
      return;
    }

    bool otpSuccess;
    String? otpErrorMessage;
    String otpIdentifier;

    if (_method == AuthMethod.phone) {
      final result = await auth.sendPhoneOtp(identifier);
      otpSuccess = result.success;
      otpErrorMessage = result.errorMessage;
      otpIdentifier = result.syntheticEmail ?? '';
    } else {
      final result = await auth.sendOtp(identifier);
      otpSuccess = result.success;
      otpErrorMessage = result.errorMessage;
      otpIdentifier = identifier;
    }

    if (!mounted) return;
    setState(() => _isCheckingAndSending = false);

    if (otpSuccess) {
      context.push(
        RouteNames.authOtp,
        extra: (
          identifier: otpIdentifier,
          phoneNumber: phoneNumber,
          isPasswordRecovery: false,
          // The account doesn't have a password yet — apply this one
          // automatically the moment OTP verification succeeds, with no
          // separate "set password" screen in between.
          pendingPassword: password,
          returnToSettingsOnSuccess: false,
        ),
      );
    } else {
      context.showErrorSnackBar(otpErrorMessage ?? context.l10n.errorUnexpected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
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
                const SizedBox(height: 8),

                Text(
                  l10n.authSignupTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ).animate().fadeIn().slideY(begin: -0.1, end: 0),

                const SizedBox(height: 8),

                Text(
                  l10n.authSignupSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ).animate(delay: 80.ms).fadeIn(),

                const SizedBox(height: 28),

                AuthMethodSelector(selected: _method, onChanged: _switchMethod)
                    .animate(delay: 140.ms)
                    .fadeIn()
                    .slideY(begin: 0.08, end: 0),

                const SizedBox(height: 24),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _method == AuthMethod.phone
                      ? TextFormField(
                          key: const ValueKey('signup-phone'),
                          controller: _inputCtrl,
                          focusNode: _inputFocus,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          maxLength: 8,
                          decoration: InputDecoration(
                            labelText: l10n.authMethodPhone,
                            hintText: '12345678',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            prefix: Text(
                              '+222 ',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            counterText: '',
                          ),
                          validator: (v) {
                            final digits =
                                v?.trim().replaceAll(RegExp(r'\D'), '') ?? '';
                            if (digits.isEmpty || digits.length < 8) {
                              return l10n.authPhoneInvalid;
                            }
                            return null;
                          },
                        )
                      : TextFormField(
                          key: const ValueKey('signup-email'),
                          controller: _inputCtrl,
                          focusNode: _inputFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: l10n.authEmailLabel,
                            hintText: l10n.authEmailHint,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            final val = v?.trim() ?? '';
                            if (val.isEmpty || !val.isValidEmail) {
                              return l10n.authEmailInvalid;
                            }
                            return null;
                          },
                        ),
                ),

                const SizedBox(height: 16),

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
                  validator: (v) =>
                      validatePasswordConfirmation(v, _passwordCtrl.text, l10n),
                ).animate(delay: 210.ms).fadeIn().slideY(begin: 0.08, end: 0),

                const SizedBox(height: 24),

                Consumer<AuthProvider>(
                  builder: (_, auth, __) => JButton(
                    label: l10n.authContinue,
                    onPressed: _submit,
                    isLoading: _isCheckingAndSending || auth.isSendingOtp,
                  ),
                ).animate(delay: 240.ms).fadeIn(),

                const SizedBox(height: 24),

                Center(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(text: '${l10n.authAlreadyHaveAccount} '),
                        TextSpan(
                          text: l10n.authLogIn,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: 270.ms).fadeIn(),

                const SizedBox(height: 24),

                Center(
                  child: Text(
                    l10n.authTermsPrivacyNotice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate(delay: 300.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
