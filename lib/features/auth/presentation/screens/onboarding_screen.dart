import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../profile/data/profile_repository.dart';

/// Profile setup screen — shown once after the first OTP verification.
///
/// Collects:
/// - Username (unique, validated against Node.js /check-username)
/// - Display name
/// - Age (optional, must be 13+)
/// - Country (optional)
/// - Preferred language
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();

  bool _isCheckingUsername = false;
  bool _isSubmitting = false;
  String? _usernameError;
  _UsernameStatus _usernameStatus = _UsernameStatus.empty;

  int? _selectedAge;
  String? _selectedCountry;
  String _selectedLanguage = 'en';

  Timer? _debounce;

  static final _usernameRegex = RegExp(r'^[a-z0-9_]{3,30}$');

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    super.dispose();
  }

  // ── Username check (debounced) ────────────────────────────────────────────
  void _onUsernameChanged(String value) {
    final normalized = value.toLowerCase().trim();
    setState(() {
      _usernameError = null;
      _usernameStatus = normalized.isEmpty
          ? _UsernameStatus.empty
          : !_usernameRegex.hasMatch(normalized)
          ? _UsernameStatus.invalid
          : _UsernameStatus.checking;
    });

    _debounce?.cancel();
    if (normalized.length < 3 || !_usernameRegex.hasMatch(normalized)) return;

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() => _isCheckingUsername = true);
      try {
        final available = await _checkUsernameAvailability(normalized);
        if (!mounted) return;
        setState(() {
          _isCheckingUsername = false;
          _usernameStatus = available
              ? _UsernameStatus.available
              : _UsernameStatus.taken;
          _usernameError = available
              ? null
              : context.l10n.onboardingUsernameTaken;
        });
      } catch (_) {
        if (mounted) setState(() => _isCheckingUsername = false);
      }
    });
  }

  Future<bool> _checkUsernameAvailability(String username) async {
    try {
      final response = await sl.apiClient.get<Map<String, dynamic>>(
        '/v1/auth/check-username',
        queryParameters: {'username': username},
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      return data?['available'] == true;
    } catch (_) {
      // On network error, allow submission and let server validate
      return true;
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_usernameError != null) return;
    if (_usernameStatus == _UsernameStatus.taken) return;
    if (_isCheckingUsername) return;

    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();

    try {
      final updated = await ProfileRepository.instance.createOrUpdateProfile(
        userId: auth.currentUser!.id,
        username: _usernameCtrl.text.trim().toLowerCase(),
        displayName: _displayNameCtrl.text.trim(),
        age: _selectedAge,
        countryCode: _selectedCountry,
        preferredLanguage: _selectedLanguage,
      );
      if (!mounted) return;
      auth.updateCurrentUser(updated);
      // GoRouter redirect handles navigation to /home
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(context.l10n.errorUnexpected);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.infoBlue, AppColors.infoLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_add_outlined,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.onboardingTitle,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            l10n.onboardingSubtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn().slideY(begin: -0.08, end: 0),

                const SizedBox(height: 36),

                // Required section
                _SectionLabel('Required'),

                const SizedBox(height: 12),

                // Username
                TextFormField(
                  controller: _usernameCtrl,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  onChanged: _onUsernameChanged,
                  decoration: InputDecoration(
                    labelText: l10n.onboardingUsernameLabel,
                    hintText: l10n.onboardingUsernameHint,
                    prefixText: '@  ',
                    errorText: _usernameError,
                    suffixIcon: _buildUsernameSuffix(),
                  ),
                  validator: (v) {
                    final val = v?.trim().toLowerCase() ?? '';
                    if (!_usernameRegex.hasMatch(val)) {
                      return l10n.onboardingUsernameInvalid;
                    }
                    return _usernameError;
                  },
                ).animate(delay: 80.ms).fadeIn(),

                const SizedBox(height: 16),

                // Display name
                TextFormField(
                  controller: _displayNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.onboardingDisplayNameLabel,
                    hintText: l10n.onboardingDisplayNameHint,
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: (v) {
                    if ((v?.trim() ?? '').length < 2)
                      return 'At least 2 characters';
                    if ((v?.trim() ?? '').length > 50)
                      return 'Maximum 50 characters';
                    return null;
                  },
                ).animate(delay: 120.ms).fadeIn(),

                const SizedBox(height: 24),

                // Optional section
                _SectionLabel('Optional'),
                const SizedBox(height: 12),

                // Language
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: const InputDecoration(
                    labelText: 'Preferred language',
                    prefixIcon: Icon(Icons.language_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'ar', child: Text('العربية')),
                    DropdownMenuItem(value: 'fr', child: Text('Français')),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedLanguage = v ?? 'en'),
                ).animate(delay: 160.ms).fadeIn(),

                const SizedBox(height: 16),

                // Age
                TextFormField(
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: '${l10n.optional} Age',
                    hintText: 'Your age (13+)',
                    prefixIcon: const Icon(Icons.cake_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final age = int.tryParse(v.trim());
                    if (age == null) return 'Enter a valid age';
                    if (age < 13) return 'You must be at least 13 years old';
                    if (age > 100) return 'Please enter a valid age';
                    return null;
                  },
                  onChanged: (v) {
                    _selectedAge = int.tryParse(v.trim());
                  },
                ).animate(delay: 200.ms).fadeIn(),

                const SizedBox(height: 32),

                JButton(
                  label: l10n.onboardingContinue,
                  onPressed:
                      (_usernameStatus == _UsernameStatus.available ||
                          _usernameStatus == _UsernameStatus.empty)
                      ? _submit
                      : null,
                  isLoading: _isSubmitting,
                ).animate(delay: 240.ms).fadeIn(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildUsernameSuffix() {
    if (_isCheckingUsername) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return switch (_usernameStatus) {
      _UsernameStatus.available => const Icon(
        Icons.check_circle_rounded,
        color: AppColors.successGreen,
      ),
      _UsernameStatus.taken => const Icon(
        Icons.cancel_rounded,
        color: AppColors.errorRed,
      ),
      _UsernameStatus.invalid => const Icon(
        Icons.error_outline_rounded,
        color: AppColors.warningAmber,
      ),
      _ => null,
    };
  }
}

enum _UsernameStatus { empty, checking, available, taken, invalid }

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: context.textTheme.labelSmall?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
