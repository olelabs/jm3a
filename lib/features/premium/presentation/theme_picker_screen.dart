// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../../../../../core/extensions/context_ext.dart';
// import '../../../../../core/providers/auth_provider.dart';
// import '../../../../../core/services/app_theme_service.dart';
// import '../../../../../core/router/route_names.dart';
// import '../../../../../core/router/app_router.dart';

// class ThemePickerScreen extends StatelessWidget {
//   const ThemePickerScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final themeService = context.watch<AppThemeService>();
//     final user = context.watch<AuthProvider>().currentUser;
//     final isPremium = user?.isPremiumActive ?? false;
//     final isPremiumPlus = user?.premiumTier == 'premium_plus';
//     final available = themeService.availableFor(
//       isPremium: isPremium,
//       isPremiumPlus: isPremiumPlus,
//     );
//     final locked = AppThemeService.allThemes
//         .where((t) => !available.contains(t))
//         .toList();
//     final appTheme = context.theme;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Themes'),
//         actions: [
//           IconButton(
//             icon: Icon(
//               themeService.isDark
//                   ? Icons.light_mode_rounded
//                   : Icons.dark_mode_rounded,
//             ),
//             onPressed: themeService.toggleDark,
//             tooltip: 'Toggle dark mode',
//           ),
//         ],
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           Text(
//             'Your Themes',
//             style: appTheme.textTheme.titleSmall?.copyWith(
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Wrap(
//             spacing: 10,
//             runSpacing: 10,
//             children: available
//                 .map(
//                   (t) => _ThemeTile(
//                     data: t,
//                     isSelected: themeService.currentId == t.id,
//                     onTap: () => themeService.setTheme(
//                       t.id,
//                       isPremiumActive: isPremium,
//                       isPremiumPlus: isPremiumPlus,
//                     ),
//                   ),
//                 )
//                 .toList(),
//           ),
//           if (locked.isNotEmpty) ...[
//             const SizedBox(height: 24),
//             Text(
//               'Premium Themes',
//               style: appTheme.textTheme.titleSmall?.copyWith(
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'Upgrade to unlock',
//               style: appTheme.textTheme.bodySmall?.copyWith(
//                 color: appTheme.colorScheme.onSurfaceVariant,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Wrap(
//               spacing: 10,
//               runSpacing: 10,
//               children: locked
//                   .map(
//                     (t) => _ThemeTile(
//                       data: t,
//                       isSelected: false,
//                       locked: true,
//                       onTap: () => AppRouter.router.push(RouteNames.premium),
//                     ),
//                   )
//                   .toList(),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// class _ThemeTile extends StatelessWidget {
//   const _ThemeTile({
//     required this.data,
//     required this.isSelected,
//     required this.onTap,
//     this.locked = false,
//   });
//   final AppThemeData data;
//   final bool isSelected;
//   final VoidCallback onTap;
//   final bool locked;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 90,
//         height: 90,
//         decoration: BoxDecoration(
//           color: data.seed.withOpacity(0.15),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: isSelected ? data.seed : Colors.grey.shade300,
//             width: isSelected ? 3 : 1,
//           ),
//         ),
//         child: Stack(
//           children: [
//             Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(data.emoji, style: const TextStyle(fontSize: 28)),
//                   const SizedBox(height: 4),
//                   Text(
//                     data.name,
//                     style: TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w700,
//                       color: data.seed,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             if (locked)
//               Container(
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.45),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: const Center(
//                   child: Icon(
//                     Icons.lock_rounded,
//                     color: Colors.white,
//                     size: 22,
//                   ),
//                 ),
//               ),
//             if (isSelected)
//               Positioned(
//                 top: 6,
//                 right: 6,
//                 child: Icon(
//                   Icons.check_circle_rounded,
//                   color: data.seed,
//                   size: 18,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/route_names.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/app_theme_service.dart';

class ThemePickerScreen extends StatelessWidget {
  const ThemePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<AppThemeService>();
    final user = context.watch<AuthProvider>().currentUser;
    final isPremium = user?.isPremiumActive ?? false;
    final isPlus = user?.premiumTier == 'premium_plus';
    final theme = context.theme;

    final available = svc.availableFor(
      isPremium: isPremium,
      isPremiumPlus: isPlus,
    );
    final locked = AppThemeService.allThemes
        .where((t) => !available.contains(t))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Theme'),
        actions: [
          IconButton(
            icon: Icon(
              svc.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            onPressed: svc.toggleDark,
            tooltip: svc.isDark ? 'Light mode' : 'Dark mode',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Your Themes',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          _ThemeGrid(
            themes: available,
            currentId: svc.currentId,
            locked: false,
            onTap: (id) => svc.setTheme(
              id,
              isPremiumActive: isPremium,
              isPremiumPlus: isPlus,
            ),
          ),
          if (locked.isNotEmpty) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                Text(
                  'Premium Themes ✦',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF5A623),
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => AppRouter.router.push(RouteNames.premium),
                  child: const Text('Upgrade →'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ThemeGrid(
              themes: locked,
              currentId: svc.currentId,
              locked: true,
              onTap: (_) => AppRouter.router.push(RouteNames.premium),
            ),
          ],
          const SizedBox(height: 28),
          Text(
            'Background Color ✦',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: isPremium ? null : const Color(0xFFF5A623),
            ),
          ),
          const SizedBox(height: 14),
          _BackgroundColorTile(
            isPremium: isPremium,
            currentHex: user?.themeBackgroundColor,
            onTap: isPremium
                ? () => AppRouter.router.push(
                    RouteNames.backgroundColor,
                    extra:
                        AppThemeService.parseHexColor(
                          user?.themeBackgroundColor,
                        ) ??
                        theme.colorScheme.surface,
                  )
                : () => AppRouter.router.push(RouteNames.premium),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _BackgroundColorTile extends StatelessWidget {
  const _BackgroundColorTile({
    required this.isPremium,
    required this.currentHex,
    required this.onTap,
  });

  final bool isPremium;
  final String? currentHex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final currentColor = AppThemeService.parseHexColor(currentHex);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: currentColor ?? theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: !isPremium
                    ? Icon(
                        Icons.lock_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  isPremium
                      ? (currentColor != null
                            ? 'Custom background set'
                            : 'Choose a background color')
                      : 'Premium feature — tap to upgrade',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeGrid extends StatelessWidget {
  const _ThemeGrid({
    required this.themes,
    required this.currentId,
    required this.locked,
    required this.onTap,
  });
  final List<AppThemeData> themes;
  final String currentId;
  final bool locked;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 3,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 0.85,
    children: themes
        .map(
          (t) => _ThemeTile(
            data: t,
            isSelected: currentId == t.id,
            locked: locked,
            onTap: () => onTap(t.id),
          ),
        )
        .toList(),
  );
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.data,
    required this.isSelected,
    required this.locked,
    required this.onTap,
  });
  final AppThemeData data;
  final bool isSelected, locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: data.primaryLight.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? data.primaryLight : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: data.primaryLight.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: data.primaryLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: data.primaryLight.withOpacity(0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      data.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: data.primaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (locked)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: data.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
