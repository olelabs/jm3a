import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/buttons/j_button.dart';

/// Route arguments for [OtpScreen]. [identifier] is what's actually used to
/// verify/resend the code — for phone sign-in this is the synthetic
/// `@phone.jma3a.internal` email Supabase auth is keyed on internally, never
/// meant to be shown to the user. [phoneNumber] is set only for the phone
/// flow and is what gets displayed instead; email sign-in leaves it null so
/// the identifier (a real email) is shown as before.
typedef OtpScreenArgs = ({
  String identifier,
  String? phoneNumber,
  bool isPasswordRecovery,
  String? pendingPassword,
  bool returnToSettingsOnSuccess,
});

/// OTP verification screen.
///
/// Features:
/// - 6-box digit entry with auto-advance
/// - Full paste support (copies across all boxes)
/// - 60-second resend countdown with visual feedback
/// - Shake animation on wrong code
/// - Remaining attempts indicator
/// - Error state per-box highlighting on failure
class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.identifier,
    this.phoneNumber,
    this.isPasswordRecovery = false,
    this.pendingPassword,
    this.returnToSettingsOnSuccess = false,
  });

  /// Value passed to verifyOtp/sendOtp — a real email for the email flow,
  /// or the internal synthetic email for the phone flow. Never shown to
  /// the user directly; see [phoneNumber].
  final String identifier;

  /// The user's real phone number, set only when this screen was reached
  /// via phone sign-in. Non-null here means the phone flow: display this
  /// instead of [identifier], and resend via sendPhoneOtp instead of
  /// sendOtp.
  final String? phoneNumber;

  /// Set when this screen was reached via the "forgot password" flow —
  /// see the navigation override in _submit() below.
  final bool isPasswordRecovery;

  /// Auth redesign: set only for signup (password collected BEFORE OTP)
  /// and the Settings "Update Password" remembers-my-password flow (new
  /// password collected right after current-password verification,
  /// before OTP). When non-null, _submit() calls setPassword with this
  /// value immediately after a successful OTP verification — the user
  /// never sees a separate "set password" screen in either flow.
  final String? pendingPassword;

  /// Only meaningful together with [pendingPassword]: true for the
  /// Settings flow (pop back to Settings with a success/error message on
  /// completion), false for signup (let the router redirect continue
  /// into onboarding, or sign out and bounce to signup on failure — see
  /// the brief's "must not continue into onboarding" requirement).
  final bool returnToSettingsOnSuccess;

  /// What to show the user and what resend should re-send to.
  String get displayIdentifier => phoneNumber ?? identifier;
  bool get isPhoneFlow => phoneNumber != null;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

/// The explicit reason this screen was reached — [pendingPassword] and
/// [isPasswordRecovery] already fully determine this; this enum just
/// names the resulting cases so _submit()'s branching reads as "which
/// flow is this" instead of a chain of boolean checks. Every current
/// call site (SignupScreen, ForgotPasswordScreen,
/// PasswordSettingsScreen's has_password=false "Set Password" prompt)
/// maps to exactly one of the first two; [none] is a defensive fallback,
/// not a case any real screen currently produces.
enum _OtpContext {
  /// Signup: password already collected and validated BEFORE this
  /// screen; applied atomically with OTP verification (see
  /// AuthProvider.verifyOtp's pendingPassword parameter). Always
  /// continues into onboarding — a brand-new account can never be
  /// otherwise ready at this exact moment.
  signup,

  /// No current password to prove identity with, so OTP verification
  /// alone must lead to the mandatory new-password step
  /// (SetPasswordScreen) — never straight into the app. Covers BOTH a
  /// genuinely forgotten password (ForgotPasswordScreen) and a Settings
  /// account establishing its first one (has_password=false): identical
  /// in kind, so identical handling.
  passwordRecovery,

  /// Verified with neither of the above set. Not reachable by any
  /// current call site — kept as an explicit, safe default (route by the
  /// account's own current state) rather than silently doing nothing if
  /// a future screen ever reaches this point without declaring which
  /// flow it's in.
  none,
}

class _OtpScreenState extends State<OtpScreen> {
  static const _len = 6;
  static const _cooldown = 60;

  final _controllers = List.generate(_len, (_) => TextEditingController());
  final _focusNodes = List.generate(_len, (_) => FocusNode());
  final _shakeKey = GlobalKey<_ShakeState>();

  int _resendSeconds = _cooldown;
  Timer? _timer;
  bool _isResending = false;
  bool _hasError = false;
  int? _attemptsRemaining;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNodes[0].requestFocus(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────
  void _startTimer() {
    setState(() => _resendSeconds = _cooldown);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() { _resendSeconds--; if (_resendSeconds <= 0) t.cancel(); });
    });
  }

  // ── OTP state ─────────────────────────────────────────────────────────────
  String get _otp => _controllers.map((c) => c.text).join();
  bool get _complete => _otp.length == _len;

  _OtpContext get _otpContext {
    if (widget.pendingPassword != null) return _OtpContext.signup;
    if (widget.isPasswordRecovery) return _OtpContext.passwordRecovery;
    return _OtpContext.none;
  }

  void _clearAll() {
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
  }

  // ── Input handling ────────────────────────────────────────────────────────
  void _onChanged(int index, String value) {
    setState(() => _hasError = false);

    if (value.isEmpty) {
      if (index > 0) _focusNodes[index - 1].requestFocus();
      return;
    }

    // Handle paste: distribute across boxes
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      for (var i = 0; i < _len && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      final next = digits.length.clamp(0, _len - 1);
      _focusNodes[next].requestFocus();
      if (_complete) _submit();
      return;
    }

    if (index < _len - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
      if (_complete) _submit();
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_complete) return;
    _focusNodes.forEach((f) => f.unfocus());

    final auth = context.read<AuthProvider>();
    // Auth redesign: signup and the Settings "remembers my password"
    // update flow both collect the password BEFORE this OTP step.
    // widget.pendingPassword, when set, is applied ATOMICALLY inside
    // this single call — see AuthProvider.verifyOtp's own doc for why
    // that atomicity (rather than a second, separate setPassword call
    // made from here afterward) avoids ever notifying an intermediate
    // "verified, no password yet" state.
    final result = await auth.verifyOtp(
      widget.identifier,
      _otp,
      pendingPassword: widget.pendingPassword,
    );

    if (!mounted) return;

    final otpContext = _otpContext;

    if (!result.success) {
      // result.otpVerified distinguishes "the code itself was wrong/
      // expired" from "the code was right, but applying pendingPassword
      // afterward failed" — never inferred from attemptsRemaining, which
      // is also null for otp_expired/otp_max_attempts and would
      // otherwise misroute those as a password-application failure.
      if (otpContext == _OtpContext.signup && result.otpVerified) {
        context.showErrorSnackBar(
          result.errorMessage ?? context.l10n.errorUnexpected,
        );
        if (widget.returnToSettingsOnSuccess) {
          // Settings flow: verifyOtp already confirmed the account's
          // existing password is untouched — back out rather than
          // re-prompting for a fresh OTP for what wasn't a wrong code.
          // go() rather than pop(): robust regardless of how deep this
          // screen was pushed, rather than depending on the exact
          // Navigator stack shape at this moment.
          context.go(RouteNames.passwordSettings);
        } else {
          // Signup: verifyOtp already rolled the just-established
          // session back — nothing to resume; start over.
          context.go(RouteNames.signup);
        }
        return;
      }

      setState(() {
        _hasError = true;
        _attemptsRemaining = result.attemptsRemaining;
      });
      _shakeKey.currentState?.shake();
      _clearAll();
      context.showErrorSnackBar(result.errorMessage ?? context.l10n.authOtpInvalid);
      return;
    }

    // Explicit per-context navigation — see _OtpContext's own doc for
    // why each case exists. Nothing here falls through to a shared
    // "generic success" path that every context implicitly relies on;
    // each case picks its own destination and returns immediately, so a
    // recovery/signup OTP can never accidentally take the plain
    // existing-account path (or vice versa).
    switch (otpContext) {
      case _OtpContext.signup:
        if (widget.returnToSettingsOnSuccess) {
          context.showSnackBar(context.l10n.passwordSettingsChangeSuccess);
          // go() rather than pop(): robust regardless of how deep this
          // screen was pushed, rather than depending on the exact
          // Navigator stack shape at this moment (see the failure branch
          // above for the same reasoning).
          context.go(RouteNames.passwordSettings);
        } else {
          // Signup: has_password is now true (set atomically inside
          // verifyOtp above), and a brand-new account always still needs
          // onboarding at this exact moment — navigate explicitly rather
          // than relying on the router's reactive redirect to catch this
          // screen, which both signup and recovery briefly sit on with
          // needsOnboarding/isLoggedIn already flipped by verifyOtp's own
          // notifyListeners() call (that reactive redirect is deliberately
          // excluded from acting on this screen — see auth_redirect.dart —
          // precisely so it never races ahead of this explicit navigation).
          context.go(RouteNames.onboarding);
        }
        return;

      case _OtpContext.passwordRecovery:
        // Forgot Password, and a Settings account establishing its first
        // password: verified identity, but there is still no password on
        // this account — MUST land on the new-password step, never
        // straight into the app. This account is typically already fully
        // ready (isLoggedIn=true, needsOnboarding=false), so the router's
        // normal post-login redirect would otherwise send this session
        // straight to /home the instant verifyOtp's notifyListeners()
        // fires — explicit navigation is required, and auth_redirect.dart
        // deliberately excludes both /auth/otp and /auth/set-password
        // from every global redirect rule so it can never race ahead of
        // this exact line.
        context.go(
          RouteNames.setPassword,
          extra: (
            isRecovery: true,
            // Threaded straight from this screen's own arg: Login's
            // Forgot Password leaves this false (continue into
            // onboarding/Home like any other successful auth); Settings'
            // Forgot Password sets it true (return to Settings instead).
            returnToSettingsOnSuccess: widget.returnToSettingsOnSuccess,
          ),
        );
        return;

      case _OtpContext.none:
        // Not reachable by any current call site (see _OtpContext.none's
        // own doc) — safe default if one is ever added without declaring
        // its context: route by whatever the account's own state says,
        // same as the router would for any other fully-authenticated
        // screen. The router's generic "stale public route -> home"
        // cleanup deliberately excludes /auth/otp (Settings' Update
        // Password legitimately revisits it while already fully ready),
        // so this screen must decide its own destination rather than
        // relying on that cleanup.
        context.go(auth.needsOnboarding ? RouteNames.onboarding : RouteNames.home);
        return;
    }
  }

  // ── Resend ────────────────────────────────────────────────────────────────
  Future<void> _resend() async {
    if (_resendSeconds > 0 || _isResending) return;
    setState(() { _isResending = true; _hasError = false; _attemptsRemaining = null; });

    final auth = context.read<AuthProvider>();
    // Phone numbers are re-sent through sendPhoneOtp (SMS), not sendOtp
    // (email) — otherwise a resend would silently try to email the
    // synthetic @phone.jma3a.internal address, which has no real mailbox.
    // phoneToSyntheticEmail is deterministic, so widget.identifier stays
    // valid across resends and doesn't need to change here. The two calls
    // return differently-shaped records, so branch fully rather than
    // ternary-assigning to one `result`.
    bool success;
    String? errorMessage;
    if (widget.isPhoneFlow) {
      final result = await auth.sendPhoneOtp(widget.phoneNumber!);
      success = result.success;
      errorMessage = result.errorMessage;
    } else {
      final result = await auth.sendOtp(widget.identifier);
      success = result.success;
      errorMessage = result.errorMessage;
    }

    if (!mounted) return;
    setState(() => _isResending = false);

    if (success) {
      _clearAll();
      _startTimer();
    } else {
      context.showErrorSnackBar(errorMessage ?? context.l10n.errorUnexpected);
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              Text(
                l10n.authOtpLabel,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn().slideY(begin: -0.08, end: 0),

              const SizedBox(height: 8),

              RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  children: [
                    const TextSpan(text: 'Code sent to '),
                    TextSpan(
                      text: widget.displayIdentifier,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 80.ms).fadeIn(),

              const SizedBox(height: 40),

              // OTP boxes
              _ShakeWidget(
                key: _shakeKey,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_len, (i) => _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    hasError: _hasError,
                    onChanged: (v) => _onChanged(i, v),
                  )),
                ),
              ).animate(delay: 160.ms).fadeIn().slideY(begin: 0.08, end: 0),

              // Attempts remaining indicator
              if (_attemptsRemaining != null) ...[
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    l10n.authOtpAttemptsRemaining(_attemptsRemaining!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              Consumer<AuthProvider>(
                builder: (_, auth, __) => JButton(
                  label: l10n.authOtpVerify,
                  onPressed: _complete ? _submit : null,
                  isLoading: auth.isVerifyingOtp,
                ),
              ),

              const SizedBox(height: 20),

              // Resend row
              Center(
                child: _resendSeconds > 0
                    ? _ResendCountdown(seconds: _resendSeconds)
                    : _ResendButton(
                        isLoading: _isResending,
                        onTap: _resend,
                        label: l10n.authOtpResend,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final errorColor = theme.colorScheme.error;

    return SizedBox(
      width: 46, height: 58,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: hasError
              ? errorColor.withOpacity(0.08)
              : theme.colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasError ? errorColor : Colors.transparent,
              width: hasError ? 1.5 : 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasError ? errorColor : Colors.transparent,
              width: hasError ? 1.5 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasError ? errorColor : theme.colorScheme.primary,
              width: 2,
            ),
          ),
        ),
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: hasError ? errorColor : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _ResendCountdown extends StatelessWidget {
  const _ResendCountdown({required this.seconds});
  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14, height: 14,
          child: CircularProgressIndicator(
            value: seconds / 60,
            strokeWidth: 1.5,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          context.l10n.authOtpResendIn(seconds),
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ResendButton extends StatelessWidget {
  const _ResendButton({
    required this.isLoading,
    required this.onTap,
    required this.label,
  });
  final bool isLoading;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onTap,
      child: isLoading
          ? const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

// ── Shake animation widget ────────────────────────────────────────────────────

class _ShakeWidget extends StatefulWidget {
  const _ShakeWidget({super.key, required this.child});
  final Widget child;

  @override
  State<_ShakeWidget> createState() => _ShakeState();
}

class _ShakeState extends State<_ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  void shake() => _ctrl.forward(from: 0);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value;
        final offset = _ctrl.isAnimating
            ? 10 * (t < 0.5 ? t : 1 - t) * ((t * 8).ceil().isEven ? 1 : -1)
            : 0.0;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: widget.child,
    );
  }
}
