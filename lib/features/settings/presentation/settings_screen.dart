import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/app_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/app_theme_service.dart';
import '../../../../core/services/app_tutorial_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_version.dart';
import '../../../../features/intro/presentation/screens/intro_screen.dart';
import '../../../../features/profile/data/profile_repository.dart';
import '../../../../shared/widgets/mouj_tech_brand.dart';
import '../../../../shared/widgets/overlays/confirm_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _presenceMode;
  bool _presenceSaving = false;

  // null while unknown/loading, then true/false once checked against the
  // server — surfaces the real pending state (not just client-side
  // bookkeeping) so the action stays correctly disabled after e.g. a
  // fresh install or a second device.
  bool? _hasPendingDeletionRequest;
  bool _deletionSubmitting = false;

  String? _versionText;

  @override
  void initState() {
    super.initState();
    ProfileRepository.instance
        .getPendingAccountDeletionRequestedAt()
        .then((requestedAt) {
          if (mounted) {
            setState(() => _hasPendingDeletionRequest = requestedAt != null);
          }
        })
        .catchError((_) {
          if (mounted) setState(() => _hasPendingDeletionRequest = false);
        });
    formattedAppVersion().then((v) {
      if (mounted) setState(() => _versionText = v);
    });
  }

  Future<void> _requestAccountDeletion() async {
    if (_hasPendingDeletionRequest == true || _deletionSubmitting) return;
    final l10n = context.l10n;

    // Reason first (required selection, "Other" requires a description),
    // then the existing consequences-confirmation dialog — two separate
    // steps so a user who backs out of the reason picker never sees the
    // destructive confirmation at all.
    final reasonResult = await showModalBottomSheet<_DeletionReasonResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DeletionReasonSheet(),
    );
    if (reasonResult == null || !mounted) return;

    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.deleteAccountDialogTitle,
      message: l10n.deleteAccountDialogMessage,
      confirmLabel: l10n.deleteAccountDialogConfirm,
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletionSubmitting = true);
    try {
      await ProfileRepository.instance.requestAccountDeletion(
        reasonCategory: reasonResult.category,
        reason: reasonResult.description,
      );
      if (mounted) {
        setState(() => _hasPendingDeletionRequest = true);
        context.showSnackBar(l10n.deleteAccountSubmitted);
      }
    } on Failure catch (_) {
      if (mounted) {
        // RLS ("account_deletion_requests: own insert") is the real
        // duplicate-prevention gate — a rejected insert here almost
        // always means a pending request already exists server-side
        // (e.g. submitted moments ago from another device), so reflect
        // that in the UI instead of just surfacing a raw error.
        setState(() => _hasPendingDeletionRequest = true);
        context.showErrorSnackBar(l10n.deleteAccountAlreadyPending);
      }
    } finally {
      if (mounted) setState(() => _deletionSubmitting = false);
    }
  }

  /// Item 12 — cancel a still-pending deletion request. See
  /// ProfileRepository.cancelAccountDeletionRequest's own doc comment for
  /// the important caveat this method respects: that call returns a bool
  /// this code MUST check, never assuming success just because the
  /// request didn't throw (an RLS-filtered-to-nothing update returns
  /// normally with zero rows, not an error). Only a confirmed true result
  /// flips this screen's local state and tells the user it worked —
  /// anything else surfaces as a real failure, never a fake success.
  Future<void> _cancelAccountDeletion() async {
    if (_hasPendingDeletionRequest != true || _deletionSubmitting) return;
    final l10n = context.l10n;

    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.settingsCancelAccountDeletionDialogTitle,
      message: l10n.settingsCancelAccountDeletionDialogMessage,
      confirmLabel: l10n.settingsCancelAccountDeletionConfirm,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletionSubmitting = true);
    try {
      final cancelled = await ProfileRepository.instance
          .cancelAccountDeletionRequest();
      if (!mounted) return;
      if (cancelled) {
        setState(() => _hasPendingDeletionRequest = false);
        context.showSnackBar(l10n.settingsAccountDeletionCancelled);
      } else {
        // Either the request is no longer pending (already processed —
        // cancellation is genuinely no longer possible, see this
        // screen's own doc comment) or the backend has no UPDATE policy
        // permitting this. Either way, re-check the real server state
        // rather than guessing which one happened.
        final requestedAt = await ProfileRepository.instance
            .getPendingAccountDeletionRequestedAt();
        if (mounted) {
          setState(() => _hasPendingDeletionRequest = requestedAt != null);
          context.showErrorSnackBar(l10n.settingsCancelAccountDeletionFailed);
        }
      }
    } catch (_) {
      if (mounted) {
        context.showErrorSnackBar(l10n.settingsCancelAccountDeletionFailed);
      }
    } finally {
      if (mounted) setState(() => _deletionSubmitting = false);
    }
  }

  Future<void> _setPresenceMode(String mode, bool isPremiumActive) async {
    if (mode != 'auto' && !isPremiumActive) return;
    setState(() {
      _presenceMode = mode;
      _presenceSaving = true;
    });
    try {
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;
      if (user != null) {
        await ProfileRepository.instance.setPresenceMode(mode);
        // Keep AuthProvider's copy in sync so anything else reading
        // currentUser.presenceMode (not just this screen's local state)
        // reflects the change without a full profile refetch.
        auth.updateCurrentUser(user.copyWith(presenceMode: mode));
      }
    } catch (_) {
      // Revert on failure — server is the source of truth.
      if (mounted) {
        setState(
          () => _presenceMode = context
              .read<AuthProvider>()
              .currentUser
              ?.presenceMode,
        );
      }
    } finally {
      if (mounted) setState(() => _presenceSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final appProvider = context.watch<AppProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    final isPremiumActive = user?.isPremiumActive ?? false;
    _presenceMode ??= user?.presenceMode ?? 'auto';

    return PopScope(
      canPop: !_signingOut,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)),
        body: Stack(
          children: [
            AbsorbPointer(
              absorbing: _signingOut,
              child: ListView(
                children: [
                  _SectionHeader(context.l10n.settingsSectionAppearance),

                  // Premium/Premium Plus already have the full App Theme
                  // customization system (colors, backgrounds — reached
                  // from the Profile screen). This basic Light/Dark/System
                  // picker is redundant for them and would just be a second,
                  // more limited place to change the same thing — Basic
                  // users, who don't have App Theme, keep it as their only
                  // option. Reuses the same isPremiumActive already read
                  // above for the presence-mode gate below, not a second
                  // premium check.
                  if (!isPremiumActive)
                    ListTile(
                      leading: const Icon(Icons.palette_outlined),
                      title: Text(l10n.settingsTheme),
                      trailing: _ThemeDropdown(
                        current: context.read<AppThemeService>().themeMode,
                        onChanged: context.read<AppThemeService>().setThemeMode,
                      ),
                    ),

                  ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: Text(l10n.settingsLanguage),
                    trailing: _LanguageDropdown(
                      current: appProvider.locale,
                      onChanged: appProvider.setLocale,
                    ),
                  ),

                  ListTile(
                    leading: _presenceSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.circle_outlined),
                    title: Text(l10n.settingsOnlineStatus),
                    subtitle: isPremiumActive
                        ? null
                        : Text(l10n.settingsOnlineStatusPremiumHint),
                    trailing: _PresenceDropdown(
                      current: _presenceMode!,
                      enabled: isPremiumActive,
                      onChanged: (mode) =>
                          _setPresenceMode(mode, isPremiumActive),
                    ),
                  ),

                  const Divider(height: 32),
                  _SectionHeader(context.l10n.settingsSectionAccount),

                  ListTile(
                    leading: const Icon(Icons.password_outlined),
                    title: Text(l10n.settingsPassword),
                    subtitle: Text(
                      (context.watch<AuthProvider>().currentUser?.hasPassword ??
                              false)
                          ? l10n.settingsPasswordSubtitleReady
                          : l10n.settingsPasswordSubtitleNotSet,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () =>
                        AppRouter.router.push(RouteNames.passwordSettings),
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.errorRed,
                    ),
                    title: Text(
                      l10n.settingsSignOut,
                      style: const TextStyle(color: AppColors.errorRed),
                    ),
                    onTap: () => _signOut(context),
                  ),

                  ListTile(
                    leading: _deletionSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.person_remove_outlined,
                            color: AppColors.errorRed,
                          ),
                    title: Text(
                      l10n.settingsRequestAccountDeletion,
                      style: const TextStyle(color: AppColors.errorRed),
                    ),
                    subtitle: _hasPendingDeletionRequest == true
                        ? Text(l10n.settingsRequestAccountDeletionPending)
                        : null,
                    enabled:
                        _hasPendingDeletionRequest != true &&
                        !_deletionSubmitting,
                    onTap: _requestAccountDeletion,
                  ),

                  // Item 12 — only offered while a request is genuinely
                  // still pending (see _hasPendingDeletionRequest, sourced
                  // from getPendingAccountDeletionRequestedAt — real
                  // server state, not client bookkeeping). Once Jma3a has
                  // accepted/processed the deletion this tile is gone, not
                  // just disabled, matching the requirement that
                  // cancellation must never be offered once it's no
                  // longer reversible.
                  if (_hasPendingDeletionRequest == true)
                    ListTile(
                      leading: const Icon(Icons.undo_rounded),
                      title: Text(l10n.settingsCancelAccountDeletion),
                      subtitle: Text(l10n.settingsCancelAccountDeletionHint),
                      enabled: !_deletionSubmitting,
                      onTap: _cancelAccountDeletion,
                    ),

                  const Divider(height: 32),
                  _SectionHeader(context.l10n.settingsSectionAbout),

                  ListTile(
                    leading: const Icon(Icons.campaign_outlined),
                    title: Text(l10n.officialResponsesTitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () =>
                        AppRouter.router.push(RouteNames.officialResponses),
                  ),

                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: Text(l10n.settingsAboutUs),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => AppRouter.router.push(RouteNames.aboutUs),
                  ),

                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(l10n.settingsPrivacyPolicy),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () =>
                        AppRouter.router.push(RouteNames.privacyPolicy),
                  ),

                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(l10n.settingsTermsConditions),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () =>
                        AppRouter.router.push(RouteNames.termsConditions),
                  ),

                  ListTile(
                    leading: const Icon(Icons.slideshow_outlined),
                    title: Text(l10n.settingsReplayIntro),
                    onTap: () async {
                      await LocalStorageService.instance.setBool(
                        kHasSeenIntroKey,
                        false,
                      );
                      if (context.mounted) context.go(RouteNames.intro);
                    },
                  ),

                  // Re-enable every first-time contextual tutorial (and the
                  // app intro) so they play again on next entry to each screen.
                  ListTile(
                    leading: const Icon(Icons.school_outlined),
                    title: Text(l10n.tutReplayTitle),
                    subtitle: Text(l10n.tutReplaySubtitle),
                    onTap: () async {
                      await AppTutorialService.instance.resetAll();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.tutReplayDone)),
                        );
                      }
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: Text(context.l10n.settingsVersionLabel),
                    trailing: _versionText == null
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _versionText!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),

                  const MoujTechBrand(),
                ],
              ),
            ),
            if (_signingOut)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.45),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          context.l10n.settingsSigningOut,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _signingOut = false;

  Future<void> _signOut(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.settingsSignOut,
      message: l10n.settingsSignOutConfirm,
      confirmLabel: l10n.settingsSignOut,
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    setState(() => _signingOut = true);
    try {
      await context.read<AppThemeService>().setTheme(
        'jma3a',
        isPremiumActive: false,
        isPremiumPlus: false,
      );
      await context.read<AppThemeService>().setThemeMode(ThemeMode.system);
      await context.read<AuthProvider>().signOut();
      if (context.mounted) context.go(RouteNames.authPasswordLogin);
    } catch (_) {
      if (context.mounted) setState(() => _signingOut = false);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Text(
      title,
      style: context.textTheme.labelLarge?.copyWith(
        color: context.colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ThemeDropdown extends StatelessWidget {
  const _ThemeDropdown({required this.current, required this.onChanged});
  final ThemeMode current;
  final void Function(ThemeMode) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DropdownButton<ThemeMode>(
      value: current,
      underline: const SizedBox.shrink(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      items: [
        DropdownMenuItem(
          value: ThemeMode.system,
          child: Text(l10n.settingsThemeSystem),
        ),
        DropdownMenuItem(
          value: ThemeMode.light,
          child: Text(l10n.settingsThemeLight),
        ),
        DropdownMenuItem(
          value: ThemeMode.dark,
          child: Text(l10n.settingsThemeDark),
        ),
      ],
    );
  }
}

class _PresenceDropdown extends StatelessWidget {
  const _PresenceDropdown({
    required this.current,
    required this.enabled,
    required this.onChanged,
  });
  final String current;
  final bool enabled;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DropdownButton<String>(
      value: current,
      underline: const SizedBox.shrink(),
      // Basic users are Auto-only — disabling instead of hiding still
      // lets them see the option exists and why it's locked (subtitle
      // hint above), same pattern as other premium-gated controls.
      onChanged: enabled
          ? (v) {
              if (v != null) onChanged(v);
            }
          : null,
      items: [
        DropdownMenuItem(value: 'auto', child: Text(l10n.presenceModeAuto)),
        DropdownMenuItem(value: 'online', child: Text(l10n.presenceModeOnline)),
        DropdownMenuItem(
          value: 'offline',
          child: Text(l10n.presenceModeOffline),
        ),
      ],
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({required this.current, required this.onChanged});
  final Locale current;
  final Future<void> Function(Locale) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Locale>(
      value: current,
      underline: const SizedBox.shrink(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      items: const [
        DropdownMenuItem(value: Locale('en'), child: Text('English')),
        DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
        DropdownMenuItem(value: Locale('fr'), child: Text('Français')),
      ],
    );
  }
}

class _DeletionReasonResult {
  const _DeletionReasonResult({required this.category, this.description});
  final String category;
  final String? description;
}

/// The 7 fixed options this app offers — reason_category's DB CHECK
/// constraint (account_deletion_requests) enumerates the exact same set,
/// so a value picked here is always valid to insert.
class _DeletionReasonSheet extends StatefulWidget {
  const _DeletionReasonSheet();

  @override
  State<_DeletionReasonSheet> createState() => _DeletionReasonSheetState();
}

class _DeletionReasonSheetState extends State<_DeletionReasonSheet> {
  String? _selected;
  final _otherController = TextEditingController();
  bool _otherTouched = false;

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selected == 'other' && _otherController.text.trim().isEmpty) {
      setState(() => _otherTouched = true);
      return;
    }
    if (_selected == null) return;
    Navigator.of(context).pop(
      _DeletionReasonResult(
        category: _selected!,
        description: _otherController.text.trim().isNotEmpty
            ? _otherController.text.trim()
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final options = <(String, String)>[
      ('no_longer_use', l10n.deleteAccountReasonNoLongerUse),
      ('privacy_concerns', l10n.deleteAccountReasonPrivacy),
      ('found_another_app', l10n.deleteAccountReasonFoundAnother),
      ('too_many_notifications', l10n.deleteAccountReasonTooManyNotifications),
      ('technical_problems', l10n.deleteAccountReasonTechnicalProblems),
      ('temporary_break', l10n.deleteAccountReasonTemporaryBreak),
      ('other', l10n.deleteAccountReasonOther),
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  l10n.deleteAccountReasonPrompt,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final (value, label) in options)
                  RadioListTile<String>(
                    value: value,
                    groupValue: _selected,
                    onChanged: (v) => setState(() => _selected = v),
                    title: Text(label),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                if (_selected == 'other') ...[
                  const SizedBox(height: 4),
                  TextField(
                    controller: _otherController,
                    maxLines: 3,
                    onChanged: (_) {
                      if (_otherTouched) setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: l10n.deleteAccountReasonOtherHint,
                      border: const OutlineInputBorder(),
                      errorText:
                          _otherTouched && _otherController.text.trim().isEmpty
                          ? l10n.deleteAccountOtherDescriptionValidation
                          : null,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _selected == null ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(l10n.deleteAccountContinueButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
