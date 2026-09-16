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
import '../../../../shared/widgets/mouj_tech_brand.dart';

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

  // ONE controller and ONE focus node for the WHOLE code — see [_OtpInput]
  // for why six separate ones were the actual iOS keyboard bug. Both are
  // created once, here, and never rebuilt: nothing in build() constructs a
  // controller or a focus node, so no parent rebuild can recreate them.
  final _codeCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _shakeKey = GlobalKey<_ShakeState>();

  // A ValueNotifier rather than setState-backed field: the resend countdown
  // ticks once a second for a minute, and a setState here rebuilt the entire
  // screen — including the OTP input — on every tick while the user was
  // still typing. Only the resend row listens to it now.
  final _resendSeconds = ValueNotifier<int>(_cooldown);
  Timer? _timer;
  bool _isResending = false;
  bool _hasError = false;
  int? _attemptsRemaining;

  // Defensive re-entrancy guard: auto-submit fires the instant the 6th
  // digit lands (_onChanged), and the Verify button is separately enabled
  // by the same 6-digit condition via its own ValueListenableBuilder —
  // two independent triggers for the same action. Without this, a tap on
  // Verify landing in the same frame as auto-submit (or a very fast
  // double-tap) could fire verifyOtp() twice concurrently for the same
  // code, burning an extra attempt from OTP_MAX_ATTEMPTS for nothing.
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    _focusNode.dispose();
    _resendSeconds.dispose();
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────
  void _startTimer() {
    _resendSeconds.value = _cooldown;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      _resendSeconds.value--;
      if (_resendSeconds.value <= 0) t.cancel();
    });
  }

  // ── OTP state ─────────────────────────────────────────────────────────────
  String get _otp => _codeCtrl.text;
  bool get _complete => _otp.length == _len;

  _OtpContext get _otpContext {
    if (widget.pendingPassword != null) return _OtpContext.signup;
    if (widget.isPasswordRecovery) return _OtpContext.passwordRecovery;
    return _OtpContext.none;
  }

  void _clearAll() {
    _codeCtrl.clear();
    _focusNode.requestFocus();
  }

  // ── Back navigation ───────────────────────────────────────────────────────
  //
  // OtpScreen is always reached via context.go() (never push()) — see
  // SignupScreen._submit/ForgotPasswordScreen._submit/
  // PasswordSettingsScreen's own comments for why: a stacked Login/Signup/
  // Settings screen left underneath would get revalidated by the router's
  // global redirect the instant OTP verification finishes, racing the
  // explicit onboarding/set-password navigation _submit() performs above.
  // That means there is nothing on the Navigator stack for a plain pop()
  // to return to — this screen must explicitly go() back to whichever
  // screen it was actually reached from, using the exact same
  // widget.pendingPassword/isPasswordRecovery/returnToSettingsOnSuccess
  // args _otpContext already derives for the SUCCESS path, rather than
  // introducing a second, separate "where did I come from" signal.
  void _goBack() {
    switch (_otpContext) {
      case _OtpContext.signup:
        // pendingPassword != null: either Signup (password collected
        // before OTP) or Settings' "remembers my password" update flow —
        // returnToSettingsOnSuccess tells the two apart, same as _submit's
        // own success branch above.
        context.go(
          widget.returnToSettingsOnSuccess
              ? RouteNames.passwordSettings
              : RouteNames.signup,
        );
      case _OtpContext.passwordRecovery:
        // isPasswordRecovery: either Login's "Forgot Password" or
        // Settings' has_password=false prompt — same distinction.
        context.go(
          widget.returnToSettingsOnSuccess
              ? RouteNames.passwordSettings
              : RouteNames.authPasswordLogin,
        );
      case _OtpContext.none:
        // Not reachable by any current call site (see _OtpContext.none's
        // own doc) — Login is the safest default entry point rather than
        // doing nothing.
        context.go(RouteNames.authPasswordLogin);
    }
  }

  // ── Input handling ────────────────────────────────────────────────────────
  //
  // Auto-advance, backspace-to-previous-box and paste-distribution are all
  // implicit now that the code lives in a single field: the caret simply
  // moves within that one field, and the boxes re-render from its text.
  // None of it touches focus any more, which is the whole point (see
  // [_OtpInput]).
  void _onChanged(String value) {
    // Only rebuild when the error state genuinely changes. This used to
    // setState unconditionally on every single keystroke.
    if (_hasError) setState(() => _hasError = false);
    if (value.length == _len) _submit();
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    // Auto-submit (onChanged reaching 6 digits) and the Verify button's own
    // ValueListenableBuilder are two independent triggers for the same
    // action — see [_submitting]'s own doc. This is the only await in the
    // whole function, so clearing the flag the instant it resolves (rather
    // than in a try/finally around every branch below) is sufficient: every
    // branch after this point is synchronous.
    if (!_complete || _submitting) return;
    _submitting = true;
    _focusNode.unfocus();

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
    _submitting = false;

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
      context.showErrorSnackBar(
        result.errorMessage ?? context.l10n.authOtpInvalid,
      );
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
        context.go(
          auth.needsOnboarding ? RouteNames.onboarding : RouteNames.home,
        );
        return;
    }
  }

  // ── Resend ────────────────────────────────────────────────────────────────
  Future<void> _resend() async {
    if (_resendSeconds.value > 0 || _isResending) return;
    setState(() {
      _isResending = true;
      _hasError = false;
      _attemptsRemaining = null;
    });

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

    return PopScope(
      // Nothing to pop to (see _goBack's own doc) — both the visible
      // back button and the Android/system back gesture route through
      // the same explicit _goBack(), matching CreatePackScreen's own
      // established "app-bar back AND system back both intercepted here"
      // convention.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _goBack),
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
                child: _OtpInput(
                  controller: _codeCtrl,
                  focusNode: _focusNode,
                  length: _len,
                  hasError: _hasError,
                  onChanged: _onChanged,
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

              // Listens to the code field directly so enabling/disabling the
              // button doesn't need a screen-wide setState per keystroke.
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _codeCtrl,
                builder: (_, value, __) => Consumer<AuthProvider>(
                  builder: (_, auth, __) => JButton(
                    label: l10n.authOtpVerify,
                    onPressed: value.text.length == _len ? _submit : null,
                    isLoading: auth.isVerifyingOtp,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Resend row — the only listener on the countdown, so its
              // per-second tick never reaches the OTP input above.
              Center(
                child: ValueListenableBuilder<int>(
                  valueListenable: _resendSeconds,
                  builder: (_, seconds, __) => seconds > 0
                      ? _ResendCountdown(seconds: seconds)
                      : _ResendButton(
                          isLoading: _isResending,
                          onTap: _resend,
                          label: l10n.authOtpResend,
                        ),
                ),
              ),

              const MoujTechBrand(size: MoujTechBrandSize.compact),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

/// The six-digit code entry: ONE real text field, six presentational boxes.
///
/// ROOT CAUSE of the iOS "keyboard closes and reopens after every digit"
/// report. This used to be six separate [TextFormField]s, each with its own
/// [TextEditingController] and [FocusNode], and `_onChanged` moved focus on
/// every keystroke (`_focusNodes[index + 1].requestFocus()`). Moving focus
/// between two distinct text fields tears the platform text-input
/// connection down and builds a new one (`TextInput.clearClient` followed by
/// `setClient`/`show`); on iOS that resigns and re-acquires first responder,
/// which visibly dismisses and re-presents the keyboard — once per digit.
///
/// Keeping the whole code in a single field means focus never moves while
/// typing, so the connection is never torn down and the keyboard simply
/// stays up. It also removes the failure mode entirely rather than masking
/// it: there is no re-focus timer, no delay, no post-rebuild
/// `requestFocus()`. The boxes below are pure presentation rendered from
/// [controller]'s text and hold no editing state, so a rebuild of this
/// widget — or of the whole screen — cannot recreate the input, its
/// controller, or its focus node.
class _OtpInput extends StatelessWidget {
  const _OtpInput({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.hasError,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    // Forces LTR for this whole subtree regardless of the app's ambient
    // locale-driven Directionality (Arabic runs the rest of the app RTL).
    // Two concrete things this fixes, not just the cursor:
    //  1. Row lays its children out along the AMBIENT text direction — in
    //     RTL that would silently reverse the six boxes' visual order
    //     (the box for the last-typed digit appearing on the left), even
    //     though each box's own digit still renders correctly on its own.
    //  2. The TextField below inherits Directionality for its internal
    //     cursor/selection movement; explicit LTR keeps that consistent
    //     even though its text is invisible.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([controller, focusNode]),
            builder: (_, __) {
              final code = controller.text;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  length,
                  (i) => _OtpBox(
                    digit: i < code.length ? code[i] : '',
                    // The box the next digit will land in.
                    isActive: focusNode.hasFocus && i == code.length,
                    hasError: hasError,
                  ),
                ),
              );
            },
          ),
          // Covers the whole row so a tap anywhere on it focuses the field,
          // exactly as tapping any individual box used to.
          Positioned.fill(
            child: TextSelectionTheme(
              // The field's own text is invisible (the boxes are what's
              // read), so its caret and selection highlight must be too.
              data: const TextSelectionThemeData(
                cursorColor: Colors.transparent,
                selectionColor: Colors.transparent,
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(length),
                ],
                onChanged: onChanged,
                showCursor: false,
                style: const TextStyle(color: Colors.transparent),
                cursorColor: Colors.transparent,
                // Deliberately a real, interactive field rather than an
                // offstage one: long-press paste of a copied code still
                // works, and pasting all six digits at once now just fills
                // the single field (the old manual paste-distribution loop
                // is gone).
                decoration: const InputDecoration(
                  // ROOT CAUSE of the stray visible input control: the
                  // app's global InputDecorationTheme (app_theme.dart) sets
                  // filled:true/fillColor plus enabledBorder/focusedBorder/
                  // errorBorder/focusedErrorBorder. Overriding only `border`
                  // (as this used to) doesn't suppress those — Flutter's
                  // InputDecoration.applyDefaults() fills each unset
                  // state-specific border from the theme independently, and
                  // enabledBorder/focusedBorder/etc. take precedence over
                  // the generic `border` fallback whenever the theme sets
                  // them. Every state has to be silenced explicitly for
                  // this field to render as nothing at all, in every state.
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                ),
                // Typing always appends — with the text invisible there is
                // no meaningful mid-string caret position to place.
                onTap: () => controller.selection = TextSelection.collapsed(
                  offset: controller.text.length,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One presentational digit box. Stateless and input-free by design — see
/// [_OtpInput].
class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.digit,
    required this.isActive,
    required this.hasError,
  });

  final String digit;
  final bool isActive;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final errorColor = theme.colorScheme.error;
    final borderColor = hasError
        ? errorColor
        : isActive
        ? theme.colorScheme.primary
        : Colors.transparent;

    return Container(
      width: 46,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hasError
            ? errorColor.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isActive || hasError ? 2 : 1,
        ),
      ),
      child: Text(
        digit,
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
          width: 14,
          height: 14,
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
              width: 16,
              height: 16,
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
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
