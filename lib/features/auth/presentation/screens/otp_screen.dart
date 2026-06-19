import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';

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
  const OtpScreen({super.key, required this.email});
  final String email;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
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
    final result = await auth.verifyOtp(widget.email, _otp);

    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _hasError = true;
        _attemptsRemaining = result.attemptsRemaining;
      });
      _shakeKey.currentState?.shake();
      _clearAll();
      context.showErrorSnackBar(result.errorMessage ?? context.l10n.authOtpInvalid);
    }
    // On success, GoRouter redirect handles navigation automatically
  }

  // ── Resend ────────────────────────────────────────────────────────────────
  Future<void> _resend() async {
    if (_resendSeconds > 0 || _isResending) return;
    setState(() { _isResending = true; _hasError = false; _attemptsRemaining = null; });

    final auth = context.read<AuthProvider>();
    final result = await auth.sendOtp(widget.email);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (result.success) {
      _clearAll();
      _startTimer();
    } else {
      context.showErrorSnackBar(result.errorMessage ?? context.l10n.errorUnexpected);
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
                      text: widget.email,
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
                    '$_attemptsRemaining attempt${_attemptsRemaining == 1 ? '' : 's'} remaining',
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
          'Resend in ${seconds}s',
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
