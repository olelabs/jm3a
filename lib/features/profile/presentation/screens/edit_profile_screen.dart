import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/image_cache_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../../../shared/widgets/overlays/loading_overlay.dart';
import '../profile_provider.dart';

/// Edit profile screen.
///
/// Allows the user to update:
/// - Avatar (from camera or gallery)
/// - Display name
/// - Bio (280 char limit)
/// - Age
/// - Country
/// - Phone number
/// - Preferred language
///
/// Username change has its own screen due to the cooldown mechanic.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _phoneCtrl;

  int? _selectedAge;
  String? _selectedCountry;
  String _selectedLanguage = 'en';

  File? _pendingAvatar; // Selected but not yet uploaded
  bool _hasPendingChanges = false;

  static const _countries = [
    ('MR', 'Mauritania'), ('MA', 'Morocco'), ('DZ', 'Algeria'),
    ('TN', 'Tunisia'), ('EG', 'Egypt'), ('SA', 'Saudi Arabia'),
    ('AE', 'UAE'), ('US', 'United States'), ('GB', 'United Kingdom'),
    ('FR', 'France'), ('DE', 'Germany'), ('Other', 'Other'),
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _displayNameCtrl = TextEditingController(text: user?.displayName ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
    _phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '');
    _selectedAge = user?.age;
    _selectedCountry = user?.countryCode;
    _selectedLanguage = user?.preferredLanguage ?? 'en';
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Avatar picker ─────────────────────────────────────────────────────────
  Future<void> _pickAvatar() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _pendingAvatar = File(picked.path);
        _hasPendingChanges = true;
      });
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ctx.theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: ctx.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final profileProvider = context.read<ProfileProvider>();

    // Upload avatar first if one was selected
    if (_pendingAvatar != null) {
      final ok = await profileProvider.uploadAvatar(_pendingAvatar!);
      if (!mounted) return;
      if (!ok) {
        context.showErrorSnackBar(
          profileProvider.lastFailure?.message ?? context.l10n.errorUnexpected,
        );
        return;
      }
    }

    // Save profile fields
    final ok = await profileProvider.updateProfile(
      displayName: _displayNameCtrl.text.trim(),
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      countryCode: _selectedCountry,
      age: _selectedAge,
      phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      preferredLanguage: _selectedLanguage,
    );

    if (!mounted) return;

    if (ok) {
      context.showSnackBar(context.l10n.profileSaved);
      context.pop();
    } else {
      context.showErrorSnackBar(
        profileProvider.lastFailure?.message ?? context.l10n.errorUnexpected,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;
    final user = context.watch<AuthProvider>().currentUser;

    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        return LoadingOverlay(
          isLoading: profileProvider.isSaving || profileProvider.isUploadingAvatar,
          message: profileProvider.isUploadingAvatar ? 'Uploading photo…' : null,
          child: Scaffold(
            appBar: AppBar(
              title: Text(l10n.profileEditTitle),
              actions: [
                TextButton(
                  onPressed: _save,
                  child: Text(
                    l10n.save,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar section
                    Center(
                      child: Stack(
                        children: [
                          _pendingAvatar != null
                              ? CircleAvatar(
                                  radius: 52,
                                  backgroundImage: FileImage(_pendingAvatar!),
                                )
                              : UserAvatar(
                                  avatarUrl: user?.avatarUrl,
                                  displayName: user?.displayName,
                                  size: 104,
                                ),
                          Positioned(
                            right: 0, bottom: 0,
                            child: GestureDetector(
                              onTap: _pickAvatar,
                              child: Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.surface,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(),

                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _pickAvatar,
                        child: Text(l10n.profileAvatarChange),
                      ),
                    ),

                    const SizedBox(height: 24),
                    _SectionHeader('Profile info'),
                    const SizedBox(height: 12),

                    // Display name
                    TextFormField(
                      controller: _displayNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() => _hasPendingChanges = true),
                      decoration: InputDecoration(
                        labelText: l10n.onboardingDisplayNameLabel,
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      validator: (v) {
                        if ((v?.trim() ?? '').length < 2) return 'At least 2 characters';
                        if ((v?.trim() ?? '').length > 50) return 'Maximum 50 characters';
                        return null;
                      },
                    ).animate(delay: 60.ms).fadeIn(),

                    const SizedBox(height: 16),

                    // Bio
                    TextFormField(
                      controller: _bioCtrl,
                      maxLength: 280,
                      maxLines: 3,
                      onChanged: (_) => setState(() => _hasPendingChanges = true),
                      decoration: InputDecoration(
                        labelText: l10n.profileBioLabel,
                        hintText: l10n.profileBioHint,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 48),
                          child: Icon(Icons.info_outline_rounded),
                        ),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) {
                        if ((v?.length ?? 0) > 280) return 'Maximum 280 characters';
                        return null;
                      },
                    ).animate(delay: 80.ms).fadeIn(),

                    const SizedBox(height: 24),
                    _SectionHeader('Personal details'),
                    const SizedBox(height: 12),

                    // Age
                    TextFormField(
                      initialValue: _selectedAge?.toString(),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) {
                        setState(() {
                          _selectedAge = int.tryParse(v.trim());
                          _hasPendingChanges = true;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: l10n.optional + ' Age',
                        prefixIcon: const Icon(Icons.cake_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final age = int.tryParse(v.trim());
                        if (age == null) return 'Enter a valid number';
                        if (age < 13) return 'Must be at least 13';
                        if (age > 100) return 'Enter a valid age';
                        return null;
                      },
                    ).animate(delay: 100.ms).fadeIn(),

                    const SizedBox(height: 16),

                    // Country
                    DropdownButtonFormField<String>(
                      value: _selectedCountry,
                      hint: Text(l10n.profileCountryLabel),
                      decoration: InputDecoration(
                        labelText: '${l10n.optional} Country',
                        prefixIcon: const Icon(Icons.flag_outlined),
                      ),
                      items: _countries
                          .map((c) => DropdownMenuItem(
                                value: c.$1,
                                child: Text(c.$2),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _selectedCountry = v;
                        _hasPendingChanges = true;
                      }),
                    ).animate(delay: 120.ms).fadeIn(),

                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => setState(() => _hasPendingChanges = true),
                      decoration: const InputDecoration(
                        labelText: 'Phone number (optional)',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '+1 555 000 0000',
                      ),
                    ).animate(delay: 140.ms).fadeIn(),

                    const SizedBox(height: 24),
                    _SectionHeader('Preferences'),
                    const SizedBox(height: 12),

                    // Language
                    DropdownButtonFormField<String>(
                      value: _selectedLanguage,
                      decoration: InputDecoration(
                        labelText: l10n.profileLanguageLabel,
                        prefixIcon: const Icon(Icons.language_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'ar', child: Text('العربية')),
                        DropdownMenuItem(value: 'fr', child: Text('Français')),
                      ],
                      onChanged: (v) => setState(() {
                        _selectedLanguage = v ?? 'en';
                        _hasPendingChanges = true;
                      }),
                    ).animate(delay: 160.ms).fadeIn(),

                    const SizedBox(height: 32),

                    JButton(
                      label: l10n.save,
                      onPressed: _hasPendingChanges ? _save : null,
                      isLoading: profileProvider.isSaving || profileProvider.isUploadingAvatar,
                    ).animate(delay: 180.ms).fadeIn(),

                    const SizedBox(height: 16),

                    // Username change button
                    OutlinedButton.icon(
                      onPressed: () => context.push('/profile/change-username'),
                      icon: const Icon(Icons.alternate_email_rounded, size: 18),
                      label: const Text('Change username'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ).animate(delay: 200.ms).fadeIn(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: context.textTheme.labelSmall?.copyWith(
        color: context.colorScheme.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
