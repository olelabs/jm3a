import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../profile/data/profile_repository.dart';

/// Profile setup screen — shown once after the first OTP verification.
///
/// Collects:
/// - Username (unique, validated against Node.js /check-username)
/// - Display name
/// - Gender (required — male/female)
/// - Age (required, must be 13+)
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
  String? _selectedGender;
  bool _genderError = false;
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

    if (_selectedGender == null) {
      setState(() => _genderError = true);
      return;
    }

    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();

    try {
      final updated = await ProfileRepository.instance.createOrUpdateProfile(
        userId: auth.currentUser!.id,
        username: _usernameCtrl.text.trim().toLowerCase(),
        displayName: _displayNameCtrl.text.trim(),
        // Non-null by construction: the Form's age/gender validators (see
        // build()) block _submit() from reaching this point otherwise.
        age: _selectedAge!,
        gender: _selectedGender!,
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
                _SectionLabel(l10n.required),

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
                      return l10n.onboardingDisplayNameTooShort;
                    if ((v?.trim() ?? '').length > 50)
                      return l10n.onboardingDisplayNameTooLong;
                    return null;
                  },
                ).animate(delay: 120.ms).fadeIn(),

                const SizedBox(height: 16),

                // Gender
                Text(
                  l10n.onboardingGenderLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _GenderOption(
                        label: l10n.onboardingGenderMale,
                        icon: Icons.male_rounded,
                        selected: _selectedGender == 'male',
                        onTap: () => setState(() {
                          _selectedGender = 'male';
                          _genderError = false;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GenderOption(
                        label: l10n.onboardingGenderFemale,
                        icon: Icons.female_rounded,
                        selected: _selectedGender == 'female',
                        onTap: () => setState(() {
                          _selectedGender = 'female';
                          _genderError = false;
                        }),
                      ),
                    ),
                  ],
                ),
                if (_genderError) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.onboardingGenderRequired,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Age
                TextFormField(
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.onboardingAgeLabel,
                    hintText: l10n.onboardingAgeHint,
                    prefixIcon: const Icon(Icons.cake_outlined),
                  ),
                  validator: (v) {
                    final trimmed = v?.trim() ?? '';
                    if (trimmed.isEmpty) return l10n.onboardingAgeRequired;
                    final age = int.tryParse(trimmed);
                    if (age == null) return l10n.onboardingAgeInvalid;
                    if (age < 13) return l10n.onboardingAgeTooYoung;
                    if (age > 100) return l10n.onboardingAgeInvalid;
                    return null;
                  },
                  onChanged: (v) {
                    _selectedAge = int.tryParse(v.trim());
                  },
                ).animate(delay: 160.ms).fadeIn(),

                const SizedBox(height: 24),

                // Optional section
                _SectionLabel(l10n.optional),
                const SizedBox(height: 12),

                // Language
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: InputDecoration(
                    labelText: l10n.profileLanguageLabel,
                    prefixIcon: const Icon(Icons.language_outlined),
                  ),
                  items: [
                    DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
                    DropdownMenuItem(value: 'ar', child: Text(l10n.languageArabic)),
                    DropdownMenuItem(value: 'fr', child: Text(l10n.languageFrench)),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedLanguage = v ?? 'en'),
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

class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? theme.colorScheme.primary.withOpacity(0.08)
              : theme.colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
