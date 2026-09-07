import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';

/// The normal login screen: identifier + password is the primary way
/// every account (new or existing) signs in. OTP only ever appears from
/// here via an explicit "Forgot password?" choice — never automatically,
/// and never as the default path.
///
/// A KNOWN account with has_password=false (a legacy pre-password-auth
/// account, or a fresh signup that hasn't verified OTP yet) gets a
/// distinct `password_not_set` error code from loginWithPassword (never
/// the generic invalid_credentials), which surfaces here as a banner
/// explaining the account has no password yet and pointing the user at
/// "Forgot password?" — the same recovery flow, not a separate "legacy
/// setup" flow.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.prefillIdentifier});

  /// Set when this screen is reached from Signup because
  /// `check-identifier` found the entered phone/email already has an
  /// account. Pre-fills the field and shows a persistent banner instead
  /// of a snackbar that could be missed.
  final String? prefillIdentifier;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _legacyNoPassword = false;
  late bool _showExistingAccountBanner = widget.prefillIdentifier != null;

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
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _legacyNoPassword = false);

    final auth = context.read<AuthProvider>();
    final result = await auth.loginWithPassword(
      _identifierCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!mounted) return;
    if (!result.success) {
      if (result.code == 'password_not_set') {
        setState(() => _legacyNoPassword = true);
        return;
      }
      context.showErrorSnackBar(
        result.errorMessage ?? context.l10n.authInvalidCredentials,
      );
    }
    // On success, GoRouter redirect handles navigation automatically.
  }

  void _goToForgotPassword() {
    // go(), not push(): a stacked auth screen left underneath would get
    // revalidated by the router's global redirect the moment recovery
    // finishes and the account becomes fully authenticated — a stale
    // /auth/login page is a "public route", so that revalidation would
    // race the explicit Set Password navigation and bounce to Home
    // before the user ever sees the new-password step.
    context.go(
      RouteNames.forgotPassword,
      extra: _identifierCtrl.text.trim(),
    );
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
                const SizedBox(height: 48),

                _BrandHeader()
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.15, end: 0),

                const SizedBox(height: 40),

                Text(
                  l10n.authWelcomeBack,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0),

                const SizedBox(height: 4),

                Text(
                  l10n.authReadyToPlay,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ).animate(delay: 140.ms).fadeIn(),

                if (_showExistingAccountBanner) ...[
                  const SizedBox(height: 20),
                  _ExistingAccountBanner(
                    onDismiss: () =>
                        setState(() => _showExistingAccountBanner = false),
                  ).animate().fadeIn().slideY(begin: -0.1, end: 0),
                ],

                const SizedBox(height: 32),

                TextFormField(
                  controller: _identifierCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.username],
                  onChanged: (_) {
                    if (_legacyNoPassword) {
                      setState(() => _legacyNoPassword = false);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: l10n.authIdentifierLabel,
                    hintText: l10n.authIdentifierHint,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) {
                      return l10n.authIdentifierRequired;
                    }
                    return null;
                  },
                ).animate(delay: 180.ms).fadeIn().slideY(begin: 0.08, end: 0),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
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
                  validator: (v) {
                    if ((v ?? '').isEmpty) return l10n.authPasswordRequired;
                    return null;
                  },
                ).animate(delay: 220.ms).fadeIn().slideY(begin: 0.08, end: 0),

                const SizedBox(height: 4),

                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => context.go(RouteNames.forgotPassword),
                    child: Text(l10n.authForgotPassword),
                  ),
                ).animate(delay: 250.ms).fadeIn(),

                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: _legacyNoPassword
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 12),
                          child: _LegacyAccountBanner(
                            onForgotPassword: _goToForgotPassword,
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),

                const SizedBox(height: 8),

                Consumer<AuthProvider>(
                  builder: (_, auth, __) => JButton(
                    label: l10n.authLogIn,
                    onPressed: _submit,
                    isLoading: auth.isLoggingInWithPassword,
                  ),
                ).animate(delay: 280.ms).fadeIn(),

                const SizedBox(height: 16),

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
                ).animate(delay: 310.ms).fadeIn(),

                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: _enterGuestMode,
                  icon: const Icon(Icons.person_outline_rounded, size: 20),
                  label: Text(l10n.authContinueAsGuest),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ).animate(delay: 340.ms).fadeIn(),

                const SizedBox(height: 28),

                Center(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(text: '${l10n.authDontHaveAccount} '),
                        TextSpan(
                          text: l10n.authCreateAccount,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.push(RouteNames.signup),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: 370.ms).fadeIn(),

                const SizedBox(height: 24),

                Center(
                  child: Text(
                    l10n.authTermsPrivacyNotice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate(delay: 400.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExistingAccountBanner extends StatelessWidget {
  const _ExistingAccountBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: cs.onSecondaryContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.authAccountAlreadyExists,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSecondaryContainer,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: cs.onSecondaryContainer),
            onPressed: onDismiss,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

/// Shown inline the moment loginWithPassword returns `password_not_set`
/// — this account (legacy, or a signup that never finished OTP) has no
/// password yet. Points at Forgot password rather than opening any
/// separate "legacy setup" flow: establishing a first password and
/// recovering a forgotten one are the exact same operation.
class _LegacyAccountBanner extends StatelessWidget {
  const _LegacyAccountBanner({required this.onForgotPassword});

  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.authLegacyNoPasswordTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.authLegacyNoPasswordBody,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          JButton(
            label: l10n.authForgotPassword,
            onPressed: onForgotPassword,
            variant: JButtonVariant.secondary,
            minimumSize: const Size(double.infinity, 44),
          ),
        ],
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
          context.l10n.appName,
          style: context.textTheme.titleLarge?.copyWith(
            color: AppColors.navyBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
