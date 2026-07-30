// // // import 'package:flutter/material.dart';
// // // import 'package:go_router/go_router.dart';
// // // import 'package:provider/provider.dart';

// // // import '../../../../core/extensions/context_ext.dart';
// // // import '../../../../core/providers/app_provider.dart';
// // // import '../../../../core/providers/auth_provider.dart';
// // // import '../../../../core/router/route_names.dart';
// // // import '../../../../core/theme/app_colors.dart';
// // // import '../../../../shared/widgets/overlays/confirm_dialog.dart';

// // // class SettingsScreen extends StatelessWidget {
// // //   const SettingsScreen({super.key});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final l10n = context.l10n;
// // //     final theme = context.theme;
// // //     final appProvider = context.watch<AppProvider>();

// // //     return Scaffold(
// // //       appBar: AppBar(title: Text(l10n.settingsTitle)),
// // //       body: ListView(
// // //         children: [
// // //           _SectionHeader('Appearance'),

// // //           // Theme
// // //           ListTile(
// // //             leading: const Icon(Icons.palette_outlined),
// // //             title: Text(l10n.settingsTheme),
// // //             trailing: _ThemeDropdown(
// // //               current: appProvider.themeMode,
// // //               onChanged: appProvider.setThemeMode,
// // //             ),
// // //           ),

// // //           // Language
// // //           ListTile(
// // //             leading: const Icon(Icons.language_outlined),
// // //             title: Text(l10n.settingsLanguage),
// // //             trailing: _LanguageDropdown(
// // //               current: appProvider.locale,
// // //               onChanged: appProvider.setLocale,
// // //             ),
// // //           ),

// // //           const Divider(height: 32),
// // //           _SectionHeader('Account'),

// // //           // Sign out
// // //           ListTile(
// // //             leading: const Icon(Icons.logout_rounded,
// // //                 color: AppColors.errorRed),
// // //             title: Text(l10n.settingsSignOut,
// // //                 style: const TextStyle(color: AppColors.errorRed)),
// // //             onTap: () => _signOut(context),
// // //           ),

// // //           const Divider(height: 32),
// // //           _SectionHeader('About'),

// // //           ListTile(
// // //             leading: const Icon(Icons.info_outline_rounded),
// // //             title: const Text('Version'),
// // //             trailing: Text('1.0.0',
// // //                 style: theme.textTheme.bodyMedium?.copyWith(
// // //                     color: theme.colorScheme.onSurfaceVariant)),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Future<void> _signOut(BuildContext context) async {
// // //     final l10n = context.l10n;
// // //     final confirmed = await showConfirmDialog(
// // //       context: context,
// // //       title: l10n.settingsSignOut,
// // //       message: l10n.settingsSignOutConfirm,
// // //       confirmLabel: l10n.settingsSignOut,
// // //       isDestructive: true,
// // //     );
// // //     if (confirmed == true && context.mounted) {
// // //       await context.read<AuthProvider>().signOut();
// // //       if (context.mounted) context.go(RouteNames.authEmail);
// // //     }
// // //   }
// // // }

// // // class _SectionHeader extends StatelessWidget {
// // //   const _SectionHeader(this.title);
// // //   final String title;

// // //   @override
// // //   Widget build(BuildContext context) => Padding(
// // //     padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
// // //     child: Text(
// // //       title,
// // //       style: context.textTheme.labelLarge?.copyWith(
// // //         color: context.colorScheme.primary,
// // //         fontWeight: FontWeight.w700,
// // //       ),
// // //     ),
// // //   );
// // // }

// // // class _ThemeDropdown extends StatelessWidget {
// // //   const _ThemeDropdown({required this.current, required this.onChanged});
// // //   final ThemeMode current;
// // //   final void Function(ThemeMode) onChanged;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final l10n = context.l10n;
// // //     return DropdownButton<ThemeMode>(
// // //       value: current,
// // //       underline: const SizedBox.shrink(),
// // //       onChanged: (v) { if (v != null) onChanged(v); },
// // //       items: [
// // //         DropdownMenuItem(
// // //             value: ThemeMode.system, child: Text(l10n.settingsThemeSystem)),
// // //         DropdownMenuItem(
// // //             value: ThemeMode.light, child: Text(l10n.settingsThemeLight)),
// // //         DropdownMenuItem(
// // //             value: ThemeMode.dark, child: Text(l10n.settingsThemeDark)),
// // //       ],
// // //     );
// // //   }
// // // }

// // // class _LanguageDropdown extends StatelessWidget {
// // //   const _LanguageDropdown({required this.current, required this.onChanged});
// // //   final Locale current;
// // //   final Future<void> Function(Locale) onChanged;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return DropdownButton<Locale>(
// // //       value: current,
// // //       underline: const SizedBox.shrink(),
// // //       onChanged: (v) { if (v != null) onChanged(v); },
// // //       items: const [
// // //         DropdownMenuItem(value: Locale('en'), child: Text('English')),
// // //         DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
// // //         DropdownMenuItem(value: Locale('fr'), child: Text('Français')),
// // //       ],
// // //     );
// // //   }
// // // }

// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/providers/app_provider.dart';
// import '../../../../core/providers/auth_provider.dart';
// import '../../../../core/router/route_names.dart';
// import '../../../../core/services/app_theme_service.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../shared/widgets/overlays/confirm_dialog.dart';

// class SettingsScreen extends StatelessWidget {
//   const SettingsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final l10n = context.l10n;
//     final theme = context.theme;
//     final appProvider = context.watch<AppProvider>();

//     return Scaffold(
//       appBar: AppBar(title: Text(l10n.settingsTitle)),
//       body: ListView(
//         children: [
//           _SectionHeader('Appearance'),

//           ListTile(
//             leading: const Icon(Icons.palette_outlined),
//             title: Text(l10n.settingsTheme),
//             trailing: _ThemeDropdown(
//               current: context.read<AppThemeService>().themeMode,
//               onChanged: context.read<AppThemeService>().setThemeMode,
//             ),
//           ),

//           // Language
//           ListTile(
//             leading: const Icon(Icons.language_outlined),
//             title: Text(l10n.settingsLanguage),
//             trailing: _LanguageDropdown(
//               current: appProvider.locale,
//               onChanged: appProvider.setLocale,
//             ),
//           ),

//           const Divider(height: 32),
//           _SectionHeader('Account'),

//           // Sign out
//           ListTile(
//             leading: const Icon(
//               Icons.logout_rounded,
//               color: AppColors.errorRed,
//             ),
//             title: Text(
//               l10n.settingsSignOut,
//               style: const TextStyle(color: AppColors.errorRed),
//             ),
//             onTap: () => _signOut(context),
//           ),

//           const Divider(height: 32),
//           _SectionHeader('About'),

//           ListTile(
//             leading: const Icon(Icons.info_outline_rounded),
//             title: const Text('Version'),
//             trailing: Text(
//               '1.0.0',
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 color: theme.colorScheme.onSurfaceVariant,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _signOut(BuildContext context) async {
//     final l10n = context.l10n;
//     final confirmed = await showConfirmDialog(
//       context: context,
//       title: l10n.settingsSignOut,
//       message: l10n.settingsSignOutConfirm,
//       confirmLabel: l10n.settingsSignOut,
//       isDestructive: true,
//     );
//     if (confirmed == true && context.mounted) {
//       await context.read<AuthProvider>().signOut();
//       if (context.mounted) context.go(RouteNames.authEmail);
//     }
//   }
// }

// class _SectionHeader extends StatelessWidget {
//   const _SectionHeader(this.title);
//   final String title;

//   @override
//   Widget build(BuildContext context) => Padding(
//     padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
//     child: Text(
//       title,
//       style: context.textTheme.labelLarge?.copyWith(
//         color: context.colorScheme.primary,
//         fontWeight: FontWeight.w700,
//       ),
//     ),
//   );
// }

// class _ThemeDropdown extends StatelessWidget {
//   const _ThemeDropdown({required this.current, required this.onChanged});
//   final ThemeMode current;
//   final void Function(ThemeMode) onChanged;

//   @override
//   Widget build(BuildContext context) {
//     final l10n = context.l10n;
//     return DropdownButton<ThemeMode>(
//       value: current,
//       underline: const SizedBox.shrink(),
//       onChanged: (v) {
//         if (v != null) onChanged(v);
//       },
//       items: [
//         DropdownMenuItem(
//           value: ThemeMode.system,
//           child: Text(l10n.settingsThemeSystem),
//         ),
//         DropdownMenuItem(
//           value: ThemeMode.light,
//           child: Text(l10n.settingsThemeLight),
//         ),
//         DropdownMenuItem(
//           value: ThemeMode.dark,
//           child: Text(l10n.settingsThemeDark),
//         ),
//       ],
//     );
//   }
// }

// class _LanguageDropdown extends StatelessWidget {
//   const _LanguageDropdown({required this.current, required this.onChanged});
//   final Locale current;
//   final Future<void> Function(Locale) onChanged;

//   @override
//   Widget build(BuildContext context) {
//     return DropdownButton<Locale>(
//       value: current,
//       underline: const SizedBox.shrink(),
//       onChanged: (v) {
//         if (v != null) onChanged(v);
//       },
//       items: const [
//         DropdownMenuItem(value: Locale('en'), child: Text('English')),
//         DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
//         DropdownMenuItem(value: Locale('fr'), child: Text('Français')),
//       ],
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/providers/app_provider.dart';
// import '../../../../core/providers/auth_provider.dart';
// import '../../../../core/router/route_names.dart';
// import '../../../../core/services/app_theme_service.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../shared/widgets/overlays/confirm_dialog.dart';

// class SettingsScreen extends StatefulWidget {
//   const SettingsScreen({super.key});
//   @override
//   State<SettingsScreen> createState() => _SettingsScreenState();
// }

// class _SettingsScreenState extends State<SettingsScreen> {
//   @override
//   Widget build(BuildContext context) {
//     final l10n = context.l10n;
//     final theme = context.theme;
//     final appProvider = context.watch<AppProvider>();

//     return Scaffold(
//       appBar: AppBar(title: Text(l10n.settingsTitle)),
//       body: ListView(
//         children: [
//           _SectionHeader('Appearance'),

//           ListTile(
//             leading: const Icon(Icons.palette_outlined),
//             title: Text(l10n.settingsTheme),
//             trailing: _ThemeDropdown(
//               current: context.read<AppThemeService>().themeMode,
//               onChanged: context.read<AppThemeService>().setThemeMode,
//             ),
//           ),

//           // Language
//           ListTile(
//             leading: const Icon(Icons.language_outlined),
//             title: Text(l10n.settingsLanguage),
//             trailing: _LanguageDropdown(
//               current: appProvider.locale,
//               onChanged: appProvider.setLocale,
//             ),
//           ),

//           const Divider(height: 32),
//           _SectionHeader('Account'),

//           ListTile(
//             leading: _signingOut
//                 ? const SizedBox(
//                     width: 24,
//                     height: 24,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                 : const Icon(Icons.logout_rounded, color: AppColors.errorRed),
//             title: Text(
//               l10n.settingsSignOut,
//               style: const TextStyle(color: AppColors.errorRed),
//             ),
//             onTap: _signingOut ? null : () => _signOut(context),
//           ),

//           const Divider(height: 32),
//           _SectionHeader('About'),

//           ListTile(
//             leading: const Icon(Icons.info_outline_rounded),
//             title: const Text('Version'),
//             trailing: Text(
//               '1.0.0',
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 color: theme.colorScheme.onSurfaceVariant,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   bool _signingOut = false;

//   Future<void> _signOut(BuildContext context) async {
//     final l10n = context.l10n;
//     final confirmed = await showConfirmDialog(
//       context: context,
//       title: l10n.settingsSignOut,
//       message: l10n.settingsSignOutConfirm,
//       confirmLabel: l10n.settingsSignOut,
//       isDestructive: true,
//     );
//     if (confirmed != true || !context.mounted) return;

//     setState(() => _signingOut = true);
//     try {
//       // Reset theme to default so login screen shows basic theme
//       await context.read<AppThemeService>().setTheme(
//         'jma3a',
//         isPremiumActive: false,
//         isPremiumPlus: false,
//       );
//       await context.read<AppThemeService>().setThemeMode(ThemeMode.system);
//       await context.read<AuthProvider>().signOut();
//       if (context.mounted) context.go(RouteNames.authEmail);
//     } catch (_) {
//       if (context.mounted) setState(() => _signingOut = false);
//     }
//   }
// }

// class _SectionHeader extends StatelessWidget {
//   const _SectionHeader(this.title);
//   final String title;

//   @override
//   Widget build(BuildContext context) => Padding(
//     padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
//     child: Text(
//       title,
//       style: context.textTheme.labelLarge?.copyWith(
//         color: context.colorScheme.primary,
//         fontWeight: FontWeight.w700,
//       ),
//     ),
//   );
// }

// class _ThemeDropdown extends StatelessWidget {
//   const _ThemeDropdown({required this.current, required this.onChanged});
//   final ThemeMode current;
//   final void Function(ThemeMode) onChanged;

//   @override
//   Widget build(BuildContext context) {
//     final l10n = context.l10n;
//     return DropdownButton<ThemeMode>(
//       value: current,
//       underline: const SizedBox.shrink(),
//       onChanged: (v) {
//         if (v != null) onChanged(v);
//       },
//       items: [
//         DropdownMenuItem(
//           value: ThemeMode.system,
//           child: Text(l10n.settingsThemeSystem),
//         ),
//         DropdownMenuItem(
//           value: ThemeMode.light,
//           child: Text(l10n.settingsThemeLight),
//         ),
//         DropdownMenuItem(
//           value: ThemeMode.dark,
//           child: Text(l10n.settingsThemeDark),
//         ),
//       ],
//     );
//   }
// }

// class _LanguageDropdown extends StatelessWidget {
//   const _LanguageDropdown({required this.current, required this.onChanged});
//   final Locale current;
//   final Future<void> Function(Locale) onChanged;

//   @override
//   Widget build(BuildContext context) {
//     return DropdownButton<Locale>(
//       value: current,
//       underline: const SizedBox.shrink(),
//       onChanged: (v) {
//         if (v != null) onChanged(v);
//       },
//       items: const [
//         DropdownMenuItem(value: Locale('en'), child: Text('English')),
//         DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
//         DropdownMenuItem(value: Locale('fr'), child: Text('Français')),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/app_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/app_theme_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/overlays/confirm_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final appProvider = context.watch<AppProvider>();

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
                  _SectionHeader('Appearance'),

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

                  const Divider(height: 32),
                  _SectionHeader('Account'),

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

                  const Divider(height: 32),
                  _SectionHeader('About'),

                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('Version'),
                    trailing: Text(
                      '1.0.0',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_signingOut)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.45),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Signing out…',
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
      if (context.mounted) context.go(RouteNames.authEmail);
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
