import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../profile_provider.dart';

/// Username change screen.
///
/// Shows:
/// - Current username
/// - Cooldown warning if applicable
/// - New username input with real-time availability check
/// - Days remaining if cooldown active
class ChangeUsernameScreen extends StatefulWidget {
  const ChangeUsernameScreen({super.key});

  @override
  State<ChangeUsernameScreen> createState() => _ChangeUsernameScreenState();
}

class _ChangeUsernameScreenState extends State<ChangeUsernameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _usernameFocus = FocusNode();

  _UsernameCheckState _checkState = _UsernameCheckState.idle;
  String? _usernameError;
  Timer? _debounce;

  static final _usernameRegex = RegExp(r'^[a-z0-9_]{3,30}$');

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameCtrl.dispose();
    _usernameFocus.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    final normalized = value.toLowerCase().trim();
    _debounce?.cancel();
    setState(() {
      _usernameError = null;
      _checkState = normalized.isEmpty
          ? _UsernameCheckState.idle
          : !_usernameRegex.hasMatch(normalized)
              ? _UsernameCheckState.invalid
              : _UsernameCheckState.checking;
    });

    if (normalized.length < 3 || !_usernameRegex.hasMatch(normalized)) return;

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() => _checkState = _UsernameCheckState.checking);
      try {
        final resp = await sl.apiClient.get<Map<String, dynamic>>(
          '/v1/auth/check-username',
          queryParameters: {'username': normalized},
        );
        final data = resp.data?['data'] as Map<String, dynamic>?;
        final available = data?['available'] == true;
        if (mounted) {
          setState(() {
            _checkState = available
                ? _UsernameCheckState.available
                : _UsernameCheckState.taken;
            _usernameError =
                available ? null : 'This username is already taken.';
          });
        }
      } catch (_) {
        if (mounted) setState(() => _checkState = _UsernameCheckState.idle);
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_checkState == _UsernameCheckState.taken) return;

    final profileProvider = context.read<ProfileProvider>();
    final result = await profileProvider.changeUsername(
      _usernameCtrl.text.trim().toLowerCase(),
    );

    if (!mounted) return;

    if (result.success) {
      context.showSnackBar('Username updated!');
      context.pop();
    } else {
      if (result.daysRemaining != null) {
        // Cooldown — show dialog
        _showCooldownDialog(result.daysRemaining!);
      } else {
        context.showErrorSnackBar(result.errorMessage ?? context.l10n.errorUnexpected);
      }
    }
  }

  void _showCooldownDialog(int daysRemaining) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cooldown active'),
        content: Text(
          'You can change your username again in $daysRemaining '
          'day${daysRemaining == 1 ? '' : 's'}.\n\n'
          'Usernames can only be changed once every 30 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final user = context.watch<AuthProvider>().currentUser;
    final cooldownDays = user?.usernameChangeCooldownDaysLeft ?? 0;
    final canChange = cooldownDays == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change username'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current username card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.alternate_email_rounded, size: 20),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Current username',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                            Text(
                              '@${user?.username ?? '—'}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),

                  const SizedBox(height: 20),

                  // Cooldown warning
                  if (!canChange) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warningAmber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warningAmber.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              color: AppColors.warningAmber, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Username change available in $cooldownDays day${cooldownDays == 1 ? '' : 's'}.\n'
                              'Changes are limited to once every 30 days.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.warningAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: 50.ms).fadeIn(),
                    const SizedBox(height: 20),
                  ],

                  // New username input
                  Text(
                    'New username',
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameCtrl,
                    focusNode: _usernameFocus,
                    enabled: canChange,
                    keyboardType: TextInputType.name,
                    autocorrect: false,
                    onChanged: canChange ? _onUsernameChanged : null,
                    decoration: InputDecoration(
                      hintText: 'lowercase_letters_123',
                      prefixText: '@  ',
                      errorText: _usernameError,
                      suffixIcon: _buildSuffix(),
                      helperText:
                          '3–30 characters · letters, numbers, underscores',
                    ),
                    validator: (v) {
                      final val = v?.trim().toLowerCase() ?? '';
                      if (!_usernameRegex.hasMatch(val)) {
                        return '3–30 chars, only a–z, 0–9, _';
                      }
                      return _usernameError;
                    },
                  ).animate(delay: 80.ms).fadeIn(),

                  const SizedBox(height: 32),

                  JButton(
                    label: 'Save username',
                    onPressed: canChange &&
                            _checkState == _UsernameCheckState.available
                        ? _submit
                        : null,
                    isLoading: profileProvider.isChangingUsername,
                  ).animate(delay: 120.ms).fadeIn(),

                  const SizedBox(height: 16),

                  Center(
                    child: Text(
                      'Username changes are permanent for 30 days.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ).animate(delay: 140.ms).fadeIn(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget? _buildSuffix() {
    return switch (_checkState) {
      _UsernameCheckState.checking => const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      _UsernameCheckState.available =>
        const Icon(Icons.check_circle_rounded, color: AppColors.successGreen),
      _UsernameCheckState.taken =>
        const Icon(Icons.cancel_rounded, color: AppColors.errorRed),
      _UsernameCheckState.invalid => const Icon(
          Icons.error_outline_rounded, color: AppColors.warningAmber),
      _ => null,
    };
  }
}

enum _UsernameCheckState { idle, checking, available, taken, invalid }
