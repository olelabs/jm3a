// // // import 'package:flutter/material.dart';
// // // import 'package:flutter/services.dart';

// // // import 'app_colors.dart';
// // // import 'app_text_styles.dart';
// // // import 'j_theme_extension.dart';

// // // /// ═══════════════════════════════════════════════════════════════
// // // /// Jma3a AppTheme
// // // /// ═══════════════════════════════════════════════════════════════
// // // ///
// // // /// Always consume via ColorScheme tokens in widgets.
// // // /// Never reference AppColors hex values in UI code.
// // // abstract final class AppTheme {
// // //   // ── Public constructors ────────────────────────────────────────────────
// // //   static ThemeData light() => _build(
// // //     brightness: Brightness.light,
// // //     colorScheme: _lightScheme,
// // //     jExtension: JThemeExtension.light,
// // //   );

// // //   static ThemeData dark() => _build(
// // //     brightness: Brightness.dark,
// // //     colorScheme: _darkScheme,
// // //     jExtension: JThemeExtension.dark,
// // //   );

// // //   // ── Light color scheme ─────────────────────────────────────────────────
// // //   static final _lightScheme = ColorScheme(
// // //     brightness: Brightness.light,

// // //     primary: AppColors.brandBlueDark,
// // //     onPrimary: AppColors.white,
// // //     primaryContainer: Color(0xFFDBEAFE),
// // //     onPrimaryContainer: AppColors.brandBlueDark,

// // //     secondary: AppColors.brandOrangeDark,
// // //     onSecondary: AppColors.white,
// // //     secondaryContainer: AppColors.brandOrangeLight,
// // //     onSecondaryContainer: AppColors.brandOrangeDark,

// // //     tertiary: AppColors.brandPurpleDark,
// // //     onTertiary: AppColors.white,
// // //     tertiaryContainer: AppColors.brandPurpleLight,
// // //     onTertiaryContainer: AppColors.brandPurpleDark,

// // //     error: AppColors.errorRed,
// // //     onError: AppColors.white,
// // //     errorContainer: AppColors.errorLight,
// // //     onErrorContainer: AppColors.errorRed,

// // //     surface: AppColors.neutral50,
// // //     onSurface: AppColors.neutral900,
// // //     surfaceContainerHighest: AppColors.neutral100,
// // //     surfaceContainerHigh: Color(0xFFECF0F7),
// // //     surfaceContainer: AppColors.white,
// // //     surfaceContainerLow: AppColors.white,
// // //     surfaceContainerLowest: AppColors.white,
// // //     onSurfaceVariant: AppColors.neutral600,

// // //     outline: AppColors.borderLight,
// // //     outlineVariant: AppColors.borderSubtle,
// // //     shadow: AppColors.black,
// // //     scrim: AppColors.black,

// // //     inverseSurface: AppColors.neutral900,
// // //     onInverseSurface: AppColors.white,
// // //     inversePrimary: AppColors.brandBlueElectric,
// // //   );

// // //   // ── Dark color scheme ──────────────────────────────────────────────────
// // //   static final _darkScheme = ColorScheme(
// // //     brightness: Brightness.dark,

// // //     primary: AppColors.brandBlueElectric,
// // //     onPrimary: AppColors.white,
// // //     primaryContainer: Color(0xFF1E3A6E),
// // //     onPrimaryContainer: Color(0xFF93C5FD),

// // //     secondary: AppColors.brandOrangeMid,
// // //     onSecondary: AppColors.white,
// // //     secondaryContainer: Color(0xFF4A1C00),
// // //     onSecondaryContainer: Color(0xFFFED7AA),

// // //     tertiary: Color(0xFF818CF8),
// // //     onTertiary: AppColors.white,
// // //     tertiaryContainer: Color(0xFF2E1065),
// // //     onTertiaryContainer: Color(0xFFDDD6FE),

// // //     error: Color(0xFFF87171),
// // //     onError: Color(0xFF7F1D1D),
// // //     errorContainer: Color(0xFF450A0A),
// // //     onErrorContainer: Color(0xFFFCA5A5),

// // //     surface: AppColors.darkBase,
// // //     onSurface: AppColors.neutral100,
// // //     surfaceContainerHighest: AppColors.darkHighest,
// // //     surfaceContainerHigh: AppColors.darkElevated,
// // //     surfaceContainer: AppColors.darkSurface,
// // //     surfaceContainerLow: AppColors.darkSurface,
// // //     surfaceContainerLowest: AppColors.darkBase,
// // //     onSurfaceVariant: AppColors.neutral400,

// // //     outline: AppColors.borderDark,
// // //     outlineVariant: AppColors.borderDarkSub,
// // //     shadow: AppColors.black,
// // //     scrim: AppColors.black,

// // //     inverseSurface: AppColors.neutral100,
// // //     onInverseSurface: AppColors.neutral900,
// // //     inversePrimary: AppColors.brandBlueDark,
// // //   );

// // //   // ── ThemeData builder ──────────────────────────────────────────────────
// // //   static ThemeData _build({
// // //     required Brightness brightness,
// // //     required ColorScheme colorScheme,
// // //     required JThemeExtension jExtension,
// // //   }) {
// // //     final isLight = brightness == Brightness.light;
// // //     final textTheme = AppTextStyles.textTheme(colorScheme);

// // //     return ThemeData(
// // //       useMaterial3: true,
// // //       brightness: brightness,
// // //       colorScheme: colorScheme,
// // //       textTheme: textTheme,
// // //       extensions: [jExtension],

// // //       // ── Scaffold ──────────────────────────────────────────────────────
// // //       scaffoldBackgroundColor: colorScheme.surface,

// // //       // ── AppBar ────────────────────────────────────────────────────────
// // //       appBarTheme: AppBarTheme(
// // //         backgroundColor: colorScheme.surface,
// // //         foregroundColor: colorScheme.onSurface,
// // //         elevation: 0,
// // //         scrolledUnderElevation: 0.5,
// // //         centerTitle: false,
// // //         surfaceTintColor: Colors.transparent,
// // //         titleTextStyle: textTheme.titleLarge?.copyWith(
// // //           fontWeight: FontWeight.w600,
// // //         ),
// // //         iconTheme: IconThemeData(color: colorScheme.onSurface, size: 22),
// // //         systemOverlayStyle: isLight
// // //             ? SystemUiOverlayStyle.dark.copyWith(
// // //                 statusBarColor: Colors.transparent,
// // //                 systemNavigationBarColor: colorScheme.surface,
// // //               )
// // //             : SystemUiOverlayStyle.light.copyWith(
// // //                 statusBarColor: Colors.transparent,
// // //                 systemNavigationBarColor: colorScheme.surface,
// // //               ),
// // //       ),

// // //       // ── Navigation bar (M3) ────────────────────────────────────────────
// // //       navigationBarTheme: NavigationBarThemeData(
// // //         backgroundColor: colorScheme.surface,
// // //         indicatorColor: colorScheme.primaryContainer,
// // //         iconTheme: WidgetStateProperty.resolveWith((states) {
// // //           if (states.contains(WidgetState.selected)) {
// // //             return IconThemeData(color: colorScheme.primary, size: 22);
// // //           }
// // //           return IconThemeData(color: colorScheme.onSurfaceVariant, size: 22);
// // //         }),
// // //         labelTextStyle: WidgetStateProperty.resolveWith((states) {
// // //           final selected = states.contains(WidgetState.selected);
// // //           return textTheme.labelSmall?.copyWith(
// // //             fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
// // //             color: selected
// // //                 ? colorScheme.primary
// // //                 : colorScheme.onSurfaceVariant,
// // //           );
// // //         }),
// // //         height: 64,
// // //         elevation: 0,
// // //         surfaceTintColor: Colors.transparent,
// // //         overlayColor: WidgetStateProperty.all(Colors.transparent),
// // //       ),

// // //       // ── Card ──────────────────────────────────────────────────────────
// // //       cardTheme: CardThemeData(
// // //         color: isLight ? AppColors.white : AppColors.darkSurface,
// // //         elevation: 0,
// // //         shape: RoundedRectangleBorder(
// // //           borderRadius: BorderRadius.circular(AppRadius.card),
// // //           side: BorderSide(
// // //             color: isLight ? AppColors.borderSubtle : AppColors.borderDark,
// // //             width: 1,
// // //           ),
// // //         ),
// // //         margin: EdgeInsets.zero,
// // //         surfaceTintColor: Colors.transparent,
// // //         clipBehavior: Clip.antiAlias,
// // //       ),

// // //       // ── Elevated button ────────────────────────────────────────────────
// // //       elevatedButtonTheme: ElevatedButtonThemeData(
// // //         style: ElevatedButton.styleFrom(
// // //           backgroundColor: colorScheme.primary,
// // //           foregroundColor: colorScheme.onPrimary,
// // //           disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.08),
// // //           disabledForegroundColor: colorScheme.onSurface.withOpacity(0.35),
// // //           elevation: 0,
// // //           shadowColor: Colors.transparent,
// // //           minimumSize: const Size(double.infinity, 52),
// // //           shape: RoundedRectangleBorder(
// // //             borderRadius: BorderRadius.circular(AppRadius.button),
// // //           ),
// // //           textStyle: textTheme.labelLarge?.copyWith(
// // //             fontWeight: FontWeight.w600,
// // //             letterSpacing: 0.2,
// // //           ),
// // //           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
// // //         ),
// // //       ),

// // //       // ── Filled button ──────────────────────────────────────────────────
// // //       filledButtonTheme: FilledButtonThemeData(
// // //         style: FilledButton.styleFrom(
// // //           minimumSize: const Size(double.infinity, 52),
// // //           shape: RoundedRectangleBorder(
// // //             borderRadius: BorderRadius.circular(AppRadius.button),
// // //           ),
// // //           textStyle: textTheme.labelLarge?.copyWith(
// // //             fontWeight: FontWeight.w600,
// // //           ),
// // //         ),
// // //       ),

// // //       // ── Outlined button ────────────────────────────────────────────────
// // //       outlinedButtonTheme: OutlinedButtonThemeData(
// // //         style: OutlinedButton.styleFrom(
// // //           side: BorderSide(color: colorScheme.outline),
// // //           minimumSize: const Size(double.infinity, 52),
// // //           shape: RoundedRectangleBorder(
// // //             borderRadius: BorderRadius.circular(AppRadius.button),
// // //           ),
// // //           textStyle: textTheme.labelLarge?.copyWith(
// // //             fontWeight: FontWeight.w600,
// // //           ),
// // //         ),
// // //       ),

// // //       // ── Text button ────────────────────────────────────────────────────
// // //       textButtonTheme: TextButtonThemeData(
// // //         style: TextButton.styleFrom(
// // //           foregroundColor: colorScheme.primary,
// // //           shape: RoundedRectangleBorder(
// // //             borderRadius: BorderRadius.circular(AppRadius.sm),
// // //           ),
// // //           textStyle: textTheme.labelLarge?.copyWith(
// // //             fontWeight: FontWeight.w600,
// // //           ),
// // //         ),
// // //       ),

// // //       // ── Input ─────────────────────────────────────────────────────────
// // //       inputDecorationTheme: InputDecorationTheme(
// // //         filled: true,
// // //         fillColor: isLight ? AppColors.neutral100 : AppColors.darkHighest,
// // //         border: _inputBorder(colorScheme.outline),
// // //         enabledBorder: _inputBorder(
// // //           isLight ? AppColors.borderSubtle : AppColors.borderDark,
// // //         ),
// // //         focusedBorder: _inputBorder(colorScheme.primary, width: 2),
// // //         errorBorder: _inputBorder(colorScheme.error),
// // //         focusedErrorBorder: _inputBorder(colorScheme.error, width: 2),
// // //         contentPadding: const EdgeInsets.symmetric(
// // //           horizontal: 16,
// // //           vertical: 15,
// // //         ),
// // //         hintStyle: textTheme.bodyMedium?.copyWith(
// // //           color: colorScheme.onSurfaceVariant,
// // //         ),
// // //         labelStyle: textTheme.bodyMedium,
// // //         floatingLabelStyle: TextStyle(
// // //           color: colorScheme.primary,
// // //           fontWeight: FontWeight.w500,
// // //         ),
// // //         prefixIconColor: colorScheme.onSurfaceVariant,
// // //         suffixIconColor: colorScheme.onSurfaceVariant,
// // //       ),

// // //       // ── Chip ──────────────────────────────────────────────────────────
// // //       chipTheme: ChipThemeData(
// // //         backgroundColor: colorScheme.surfaceContainerHighest,
// // //         selectedColor: colorScheme.primaryContainer,
// // //         checkmarkColor: colorScheme.primary,
// // //         labelStyle: textTheme.labelMedium,
// // //         shape: RoundedRectangleBorder(
// // //           borderRadius: BorderRadius.circular(AppRadius.chip),
// // //         ),
// // //         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
// // //         side: BorderSide.none,
// // //       ),

// // //       // ── Dialog ────────────────────────────────────────────────────────
// // //       dialogTheme: DialogThemeData(
// // //         backgroundColor: isLight ? AppColors.white : AppColors.darkSurface,
// // //         surfaceTintColor: Colors.transparent,
// // //         shape: RoundedRectangleBorder(
// // //           borderRadius: BorderRadius.circular(AppRadius.dialog),
// // //         ),
// // //         elevation: 4,
// // //         titleTextStyle: textTheme.headlineSmall,
// // //         contentTextStyle: textTheme.bodyMedium,
// // //       ),

// // //       // ── Bottom sheet ──────────────────────────────────────────────────
// // //       bottomSheetTheme: BottomSheetThemeData(
// // //         backgroundColor: isLight ? AppColors.white : AppColors.darkSurface,
// // //         surfaceTintColor: Colors.transparent,
// // //         shape: const RoundedRectangleBorder(
// // //           borderRadius: BorderRadius.vertical(
// // //             top: Radius.circular(AppRadius.sheet),
// // //           ),
// // //         ),
// // //         elevation: 0,
// // //         showDragHandle: true,
// // //         dragHandleColor: colorScheme.onSurfaceVariant.withOpacity(0.4),
// // //         dragHandleSize: const Size(36, 4),
// // //       ),

// // //       // ── Divider ───────────────────────────────────────────────────────
// // //       dividerTheme: DividerThemeData(
// // //         color: colorScheme.outlineVariant,
// // //         thickness: 1,
// // //         space: 1,
// // //       ),

// // //       // ── Snack bar ─────────────────────────────────────────────────────
// // //       snackBarTheme: SnackBarThemeData(
// // //         behavior: SnackBarBehavior.floating,
// // //         shape: RoundedRectangleBorder(
// // //           borderRadius: BorderRadius.circular(AppRadius.md),
// // //         ),
// // //         backgroundColor: isLight
// // //             ? AppColors.neutral900
// // //             : AppColors.darkElevated,
// // //         contentTextStyle: textTheme.bodyMedium?.copyWith(
// // //           color: isLight ? AppColors.white : AppColors.neutral100,
// // //         ),
// // //         elevation: 4,
// // //         insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// // //       ),

// // //       // ── Switch ────────────────────────────────────────────────────────
// // //       switchTheme: SwitchThemeData(
// // //         thumbColor: WidgetStateProperty.resolveWith((states) {
// // //           if (states.contains(WidgetState.selected)) return colorScheme.primary;
// // //           return colorScheme.onSurfaceVariant;
// // //         }),
// // //         trackColor: WidgetStateProperty.resolveWith((states) {
// // //           if (states.contains(WidgetState.selected)) {
// // //             return colorScheme.primaryContainer;
// // //           }
// // //           return colorScheme.surfaceContainerHighest;
// // //         }),
// // //       ),

// // //       // ── Progress indicator ────────────────────────────────────────────
// // //       progressIndicatorTheme: ProgressIndicatorThemeData(
// // //         color: colorScheme.primary,
// // //         circularTrackColor: colorScheme.surfaceContainerHighest,
// // //         linearTrackColor: colorScheme.surfaceContainerHighest,
// // //         linearMinHeight: 4,
// // //       ),

// // //       // ── List tile ─────────────────────────────────────────────────────
// // //       listTileTheme: ListTileThemeData(
// // //         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
// // //         titleTextStyle: textTheme.titleSmall,
// // //         subtitleTextStyle: textTheme.bodySmall,
// // //         iconColor: colorScheme.onSurfaceVariant,
// // //         shape: RoundedRectangleBorder(
// // //           borderRadius: BorderRadius.circular(AppRadius.md),
// // //         ),
// // //       ),

// // //       // ── Icon button ───────────────────────────────────────────────────
// // //       iconButtonTheme: IconButtonThemeData(
// // //         style: IconButton.styleFrom(
// // //           shape: RoundedRectangleBorder(
// // //             borderRadius: BorderRadius.circular(AppRadius.sm),
// // //           ),
// // //         ),
// // //       ),

// // //       // ── Tab bar ───────────────────────────────────────────────────────
// // //       tabBarTheme: TabBarThemeData(
// // //         indicatorColor: colorScheme.primary,
// // //         labelColor: colorScheme.primary,
// // //         unselectedLabelColor: colorScheme.onSurfaceVariant,
// // //         labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
// // //         unselectedLabelStyle: textTheme.labelLarge,
// // //         dividerColor: colorScheme.outlineVariant,
// // //         tabAlignment: TabAlignment.start,
// // //         indicatorSize: TabBarIndicatorSize.label,
// // //         overlayColor: WidgetStateProperty.all(Colors.transparent),
// // //       ),

// // //       // ── Slider ────────────────────────────────────────────────────────
// // //       sliderTheme: SliderThemeData(
// // //         activeTrackColor: colorScheme.primary,
// // //         inactiveTrackColor: colorScheme.surfaceContainerHighest,
// // //         thumbColor: colorScheme.primary,
// // //         overlayColor: colorScheme.primary.withOpacity(0.1),
// // //         trackHeight: 4,
// // //       ),

// // //       // ── Popup menu ────────────────────────────────────────────────────
// // //       popupMenuTheme: PopupMenuThemeData(
// // //         color: isLight ? AppColors.white : AppColors.darkElevated,
// // //         surfaceTintColor: Colors.transparent,
// // //         shape: RoundedRectangleBorder(
// // //           borderRadius: BorderRadius.circular(AppRadius.md),
// // //         ),
// // //         elevation: 8,
// // //         textStyle: textTheme.bodyMedium,
// // //         shadowColor: AppColors.black.withOpacity(0.2),
// // //       ),

// // //       // ── Tooltip ───────────────────────────────────────────────────────
// // //       tooltipTheme: TooltipThemeData(
// // //         decoration: BoxDecoration(
// // //           color: isLight ? AppColors.neutral900 : AppColors.darkElevated,
// // //           borderRadius: BorderRadius.circular(AppRadius.sm),
// // //         ),
// // //         textStyle: textTheme.labelSmall?.copyWith(
// // //           color: isLight ? AppColors.white : AppColors.neutral100,
// // //         ),
// // //       ),

// // //       // ── Search bar ────────────────────────────────────────────────────
// // //       searchBarTheme: SearchBarThemeData(
// // //         backgroundColor: WidgetStateProperty.all(
// // //           isLight ? AppColors.neutral100 : AppColors.darkHighest,
// // //         ),
// // //         surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
// // //         elevation: WidgetStateProperty.all(0),
// // //         shape: WidgetStateProperty.all(
// // //           RoundedRectangleBorder(
// // //             borderRadius: BorderRadius.circular(AppRadius.button),
// // //           ),
// // //         ),
// // //         textStyle: WidgetStateProperty.all(textTheme.bodyMedium),
// // //         hintStyle: WidgetStateProperty.all(
// // //           textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
// // //         ),
// // //       ),

// // //       // ── Badge ─────────────────────────────────────────────────────────
// // //       badgeTheme: BadgeThemeData(
// // //         backgroundColor: colorScheme.secondary,
// // //         textColor: colorScheme.onSecondary,
// // //         textStyle: textTheme.labelSmall?.copyWith(fontSize: 10),
// // //       ),
// // //     );
// // //   }

// // //   static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
// // //       OutlineInputBorder(
// // //         borderRadius: BorderRadius.circular(AppRadius.input),
// // //         borderSide: BorderSide(color: color, width: width),
// // //       );
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';

// // import 'app_colors.dart';
// // import 'app_text_styles.dart';
// // import 'j_theme_extension.dart';

// // /// ═══════════════════════════════════════════════════════════════
// // /// Jma3a AppTheme
// // /// ═══════════════════════════════════════════════════════════════
// // ///
// // /// Always consume via ColorScheme tokens in widgets.
// // /// Never reference AppColors hex values in UI code.
// // abstract final class AppTheme {
// //   // ── Public constructors ────────────────────────────────────────────────
// //   static ThemeData light() => _build(
// //     brightness: Brightness.light,
// //     colorScheme: _lightScheme,
// //     jExtension: JThemeExtension.light,
// //   );

// //   static ThemeData dark() => _build(
// //     brightness: Brightness.dark,
// //     colorScheme: _darkScheme,
// //     jExtension: JThemeExtension.dark,
// //   );

// //   // ── Light color scheme ─────────────────────────────────────────────────
// //   static final _lightScheme = ColorScheme(
// //     brightness: Brightness.light,

// //     primary: AppColors.brandBlueDark,
// //     onPrimary: AppColors.white,
// //     primaryContainer: Color(0xFFDBEAFE),
// //     onPrimaryContainer: AppColors.brandBlueDark,

// //     secondary: AppColors.brandOrangeDark,
// //     onSecondary: AppColors.white,
// //     secondaryContainer: AppColors.brandOrangeLight,
// //     onSecondaryContainer: AppColors.brandOrangeDark,

// //     tertiary: AppColors.brandPurpleDark,
// //     onTertiary: AppColors.white,
// //     tertiaryContainer: AppColors.brandPurpleLight,
// //     onTertiaryContainer: AppColors.brandPurpleDark,

// //     error: AppColors.errorRed,
// //     onError: AppColors.white,
// //     errorContainer: AppColors.errorLight,
// //     onErrorContainer: AppColors.errorRed,

// //     surface: AppColors.neutral50,
// //     onSurface: AppColors.neutral900,
// //     surfaceContainerHighest: AppColors.neutral100,
// //     surfaceContainerHigh: Color(0xFFECF0F7),
// //     surfaceContainer: AppColors.white,
// //     surfaceContainerLow: AppColors.white,
// //     surfaceContainerLowest: AppColors.white,
// //     onSurfaceVariant: AppColors.neutral600,

// //     outline: AppColors.borderLight,
// //     outlineVariant: AppColors.borderSubtle,
// //     shadow: AppColors.black,
// //     scrim: AppColors.black,

// //     inverseSurface: AppColors.neutral900,
// //     onInverseSurface: AppColors.white,
// //     inversePrimary: AppColors.brandBlueElectric,
// //   );

// //   // ── Dark color scheme ──────────────────────────────────────────────────
// //   static final _darkScheme = ColorScheme(
// //     brightness: Brightness.dark,

// //     primary: AppColors.brandBlueElectric,
// //     onPrimary: AppColors.white,
// //     primaryContainer: Color(0xFF1E3A6E),
// //     onPrimaryContainer: Color(0xFF93C5FD),

// //     secondary: AppColors.brandOrangeMid,
// //     onSecondary: AppColors.white,
// //     secondaryContainer: Color(0xFF4A1C00),
// //     onSecondaryContainer: Color(0xFFFED7AA),

// //     tertiary: Color(0xFF818CF8),
// //     onTertiary: AppColors.white,
// //     tertiaryContainer: Color(0xFF2E1065),
// //     onTertiaryContainer: Color(0xFFDDD6FE),

// //     error: Color(0xFFF87171),
// //     onError: Color(0xFF7F1D1D),
// //     errorContainer: Color(0xFF450A0A),
// //     onErrorContainer: Color(0xFFFCA5A5),

// //     surface: AppColors.darkBase,
// //     onSurface: AppColors.neutral100,
// //     surfaceContainerHighest: AppColors.darkHighest,
// //     surfaceContainerHigh: AppColors.darkElevated,
// //     surfaceContainer: AppColors.darkSurface,
// //     surfaceContainerLow: AppColors.darkSurface,
// //     surfaceContainerLowest: AppColors.darkBase,
// //     onSurfaceVariant: AppColors.neutral400,

// //     outline: AppColors.borderDark,
// //     outlineVariant: AppColors.borderDarkSub,
// //     shadow: AppColors.black,
// //     scrim: AppColors.black,

// //     inverseSurface: AppColors.neutral100,
// //     onInverseSurface: AppColors.neutral900,
// //     inversePrimary: AppColors.brandBlueDark,
// //   );

// //   // ── ThemeData builder ──────────────────────────────────────────────────
// //   static ThemeData _build({
// //     required Brightness brightness,
// //     required ColorScheme colorScheme,
// //     required JThemeExtension jExtension,
// //   }) {
// //     final isLight = brightness == Brightness.light;
// //     final textTheme = AppTextStyles.textTheme(colorScheme);

// //     return ThemeData(
// //       useMaterial3: true,
// //       brightness: brightness,
// //       colorScheme: colorScheme,
// //       textTheme: textTheme,
// //       extensions: [jExtension],

// //       // ── Scaffold ──────────────────────────────────────────────────────
// //       scaffoldBackgroundColor: colorScheme.surface,

// //       // ── AppBar ────────────────────────────────────────────────────────
// //       appBarTheme: AppBarTheme(
// //         backgroundColor: colorScheme.surface,
// //         foregroundColor: colorScheme.onSurface,
// //         elevation: 0,
// //         scrolledUnderElevation: 0.5,
// //         centerTitle: false,
// //         surfaceTintColor: Colors.transparent,
// //         titleTextStyle: textTheme.titleLarge?.copyWith(
// //           fontWeight: FontWeight.w600,
// //         ),
// //         iconTheme: IconThemeData(color: colorScheme.onSurface, size: 22),
// //         systemOverlayStyle: isLight
// //             ? SystemUiOverlayStyle.dark.copyWith(
// //                 statusBarColor: Colors.transparent,
// //                 systemNavigationBarColor: colorScheme.surface,
// //               )
// //             : SystemUiOverlayStyle.light.copyWith(
// //                 statusBarColor: Colors.transparent,
// //                 systemNavigationBarColor: colorScheme.surface,
// //               ),
// //       ),

// //       // ── Navigation bar (M3) ────────────────────────────────────────────
// //       navigationBarTheme: NavigationBarThemeData(
// //         backgroundColor: colorScheme.surface,
// //         indicatorColor: colorScheme.primaryContainer,
// //         iconTheme: WidgetStateProperty.resolveWith((states) {
// //           if (states.contains(WidgetState.selected)) {
// //             return IconThemeData(color: colorScheme.primary, size: 22);
// //           }
// //           return IconThemeData(color: colorScheme.onSurfaceVariant, size: 22);
// //         }),
// //         labelTextStyle: WidgetStateProperty.resolveWith((states) {
// //           final selected = states.contains(WidgetState.selected);
// //           return textTheme.labelSmall?.copyWith(
// //             fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
// //             color: selected
// //                 ? colorScheme.primary
// //                 : colorScheme.onSurfaceVariant,
// //           );
// //         }),
// //         height: 64,
// //         elevation: 0,
// //         surfaceTintColor: Colors.transparent,
// //         overlayColor: WidgetStateProperty.all(Colors.transparent),
// //       ),

// //       // ── Card ──────────────────────────────────────────────────────────
// //       cardTheme: CardThemeData(
// //         color: isLight ? AppColors.white : AppColors.darkSurface,
// //         elevation: 0,
// //         shape: RoundedRectangleBorder(
// //           borderRadius: BorderRadius.circular(AppRadius.card),
// //           side: BorderSide(
// //             color: isLight ? AppColors.borderSubtle : AppColors.borderDark,
// //             width: 1,
// //           ),
// //         ),
// //         margin: EdgeInsets.zero,
// //         surfaceTintColor: Colors.transparent,
// //         clipBehavior: Clip.antiAlias,
// //       ),

// //       // ── Elevated button ────────────────────────────────────────────────
// //       elevatedButtonTheme: ElevatedButtonThemeData(
// //         style: ElevatedButton.styleFrom(
// //           backgroundColor: colorScheme.primary,
// //           foregroundColor: colorScheme.onPrimary,
// //           disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.08),
// //           disabledForegroundColor: colorScheme.onSurface.withOpacity(0.35),
// //           elevation: 0,
// //           shadowColor: Colors.transparent,
// //           minimumSize: const Size(double.infinity, 52),
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(AppRadius.button),
// //           ),
// //           textStyle: textTheme.labelLarge?.copyWith(
// //             fontWeight: FontWeight.w600,
// //             letterSpacing: 0.2,
// //           ),
// //           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
// //         ),
// //       ),

// //       // ── Filled button ──────────────────────────────────────────────────
// //       filledButtonTheme: FilledButtonThemeData(
// //         style: FilledButton.styleFrom(
// //           minimumSize: const Size(double.infinity, 52),
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(AppRadius.button),
// //           ),
// //           textStyle: textTheme.labelLarge?.copyWith(
// //             fontWeight: FontWeight.w600,
// //           ),
// //         ),
// //       ),

// //       // ── Outlined button ────────────────────────────────────────────────
// //       outlinedButtonTheme: OutlinedButtonThemeData(
// //         style: OutlinedButton.styleFrom(
// //           side: BorderSide(color: colorScheme.outline),
// //           minimumSize: const Size(double.infinity, 52),
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(AppRadius.button),
// //           ),
// //           textStyle: textTheme.labelLarge?.copyWith(
// //             fontWeight: FontWeight.w600,
// //           ),
// //         ),
// //       ),

// //       // ── Text button ────────────────────────────────────────────────────
// //       textButtonTheme: TextButtonThemeData(
// //         style: TextButton.styleFrom(
// //           foregroundColor: colorScheme.primary,
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(AppRadius.sm),
// //           ),
// //           textStyle: textTheme.labelLarge?.copyWith(
// //             fontWeight: FontWeight.w600,
// //           ),
// //         ),
// //       ),

// //       // ── Input ─────────────────────────────────────────────────────────
// //       inputDecorationTheme: InputDecorationTheme(
// //         filled: true,
// //         fillColor: isLight ? AppColors.neutral100 : AppColors.darkHighest,
// //         border: _inputBorder(colorScheme.outline),
// //         enabledBorder: _inputBorder(
// //           isLight ? AppColors.borderSubtle : AppColors.borderDark,
// //         ),
// //         focusedBorder: _inputBorder(colorScheme.primary, width: 2),
// //         errorBorder: _inputBorder(colorScheme.error),
// //         focusedErrorBorder: _inputBorder(colorScheme.error, width: 2),
// //         contentPadding: const EdgeInsets.symmetric(
// //           horizontal: 16,
// //           vertical: 15,
// //         ),
// //         hintStyle: textTheme.bodyMedium?.copyWith(
// //           color: colorScheme.onSurfaceVariant,
// //         ),
// //         labelStyle: textTheme.bodyMedium,
// //         floatingLabelStyle: TextStyle(
// //           color: colorScheme.primary,
// //           fontWeight: FontWeight.w500,
// //         ),
// //         prefixIconColor: colorScheme.onSurfaceVariant,
// //         suffixIconColor: colorScheme.onSurfaceVariant,
// //       ),

// //       // ── Chip ──────────────────────────────────────────────────────────
// //       chipTheme: ChipThemeData(
// //         backgroundColor: colorScheme.surfaceContainerHighest,
// //         selectedColor: colorScheme.primaryContainer,
// //         checkmarkColor: colorScheme.primary,
// //         labelStyle: textTheme.labelMedium,
// //         shape: RoundedRectangleBorder(
// //           borderRadius: BorderRadius.circular(AppRadius.chip),
// //         ),
// //         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
// //         side: BorderSide.none,
// //       ),

// //       // ── Dialog ────────────────────────────────────────────────────────
// //       dialogTheme: DialogThemeData(
// //         backgroundColor: isLight ? AppColors.white : AppColors.darkSurface,
// //         surfaceTintColor: Colors.transparent,
// //         shape: RoundedRectangleBorder(
// //           borderRadius: BorderRadius.circular(AppRadius.dialog),
// //         ),
// //         elevation: 4,
// //         titleTextStyle: textTheme.headlineSmall,
// //         contentTextStyle: textTheme.bodyMedium,
// //       ),

// //       // ── Bottom sheet ──────────────────────────────────────────────────
// //       bottomSheetTheme: BottomSheetThemeData(
// //         backgroundColor: isLight ? AppColors.white : AppColors.darkSurface,
// //         surfaceTintColor: Colors.transparent,
// //         shape: const RoundedRectangleBorder(
// //           borderRadius: BorderRadius.vertical(
// //             top: Radius.circular(AppRadius.sheet),
// //           ),
// //         ),
// //         elevation: 0,
// //         showDragHandle: true,
// //         dragHandleColor: colorScheme.onSurfaceVariant.withOpacity(0.4),
// //         dragHandleSize: const Size(36, 4),
// //       ),

// //       // ── Divider ───────────────────────────────────────────────────────
// //       dividerTheme: DividerThemeData(
// //         color: colorScheme.outlineVariant,
// //         thickness: 1,
// //         space: 1,
// //       ),

// //       // ── Snack bar ─────────────────────────────────────────────────────
// //       snackBarTheme: SnackBarThemeData(
// //         behavior: SnackBarBehavior.floating,
// //         shape: RoundedRectangleBorder(
// //           borderRadius: BorderRadius.circular(AppRadius.md),
// //         ),
// //         backgroundColor: isLight
// //             ? AppColors.neutral900
// //             : AppColors.darkElevated,
// //         contentTextStyle: textTheme.bodyMedium?.copyWith(
// //           color: isLight ? AppColors.white : AppColors.neutral100,
// //         ),
// //         elevation: 4,
// //         insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //       ),

// //       // ── Switch ────────────────────────────────────────────────────────
// //       switchTheme: SwitchThemeData(
// //         thumbColor: WidgetStateProperty.resolveWith((states) {
// //           if (states.contains(WidgetState.selected)) return colorScheme.primary;
// //           return colorScheme.onSurfaceVariant;
// //         }),
// //         trackColor: WidgetStateProperty.resolveWith((states) {
// //           if (states.contains(WidgetState.selected)) {
// //             return colorScheme.primaryContainer;
// //           }
// //           return colorScheme.surfaceContainerHighest;
// //         }),
// //       ),

// //       // ── Progress indicator ────────────────────────────────────────────
// //       progressIndicatorTheme: ProgressIndicatorThemeData(
// //         color: colorScheme.primary,
// //         circularTrackColor: colorScheme.surfaceContainerHighest,
// //         linearTrackColor: colorScheme.surfaceContainerHighest,
// //         linearMinHeight: 4,
// //       ),

// //       // ── List tile ─────────────────────────────────────────────────────
// //       listTileTheme: ListTileThemeData(
// //         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
// //         titleTextStyle: textTheme.titleSmall,
// //         subtitleTextStyle: textTheme.bodySmall,
// //         iconColor: colorScheme.onSurfaceVariant,
// //         shape: RoundedRectangleBorder(
// //           borderRadius: BorderRadius.circular(AppRadius.md),
// //         ),
// //       ),

// //       // ── Icon button ───────────────────────────────────────────────────
// //       iconButtonTheme: IconButtonThemeData(
// //         style: IconButton.styleFrom(
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(AppRadius.sm),
// //           ),
// //         ),
// //       ),

// //       // ── Tab bar ───────────────────────────────────────────────────────
// //       tabBarTheme: TabBarThemeData(
// //         indicatorColor: colorScheme.primary,
// //         labelColor: colorScheme.primary,
// //         unselectedLabelColor: colorScheme.onSurfaceVariant,
// //         labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
// //         unselectedLabelStyle: textTheme.labelLarge,
// //         dividerColor: colorScheme.outlineVariant,
// //         tabAlignment: TabAlignment.fill,
// //         indicatorSize: TabBarIndicatorSize.label,
// //         overlayColor: WidgetStateProperty.all(Colors.transparent),
// //       ),

// //       // ── Slider ────────────────────────────────────────────────────────
// //       sliderTheme: SliderThemeData(
// //         activeTrackColor: colorScheme.primary,
// //         inactiveTrackColor: colorScheme.surfaceContainerHighest,
// //         thumbColor: colorScheme.primary,
// //         overlayColor: colorScheme.primary.withOpacity(0.1),
// //         trackHeight: 4,
// //       ),

// //       // ── Popup menu ────────────────────────────────────────────────────
// //       popupMenuTheme: PopupMenuThemeData(
// //         color: isLight ? AppColors.white : AppColors.darkElevated,
// //         surfaceTintColor: Colors.transparent,
// //         shape: RoundedRectangleBorder(
// //           borderRadius: BorderRadius.circular(AppRadius.md),
// //         ),
// //         elevation: 8,
// //         textStyle: textTheme.bodyMedium,
// //         shadowColor: AppColors.black.withOpacity(0.2),
// //       ),

// //       // ── Tooltip ───────────────────────────────────────────────────────
// //       tooltipTheme: TooltipThemeData(
// //         decoration: BoxDecoration(
// //           color: isLight ? AppColors.neutral900 : AppColors.darkElevated,
// //           borderRadius: BorderRadius.circular(AppRadius.sm),
// //         ),
// //         textStyle: textTheme.labelSmall?.copyWith(
// //           color: isLight ? AppColors.white : AppColors.neutral100,
// //         ),
// //       ),

// //       // ── Search bar ────────────────────────────────────────────────────
// //       searchBarTheme: SearchBarThemeData(
// //         backgroundColor: WidgetStateProperty.all(
// //           isLight ? AppColors.neutral100 : AppColors.darkHighest,
// //         ),
// //         surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
// //         elevation: WidgetStateProperty.all(0),
// //         shape: WidgetStateProperty.all(
// //           RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(AppRadius.button),
// //           ),
// //         ),
// //         textStyle: WidgetStateProperty.all(textTheme.bodyMedium),
// //         hintStyle: WidgetStateProperty.all(
// //           textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
// //         ),
// //       ),

// //       // ── Badge ─────────────────────────────────────────────────────────
// //       badgeTheme: BadgeThemeData(
// //         backgroundColor: colorScheme.secondary,
// //         textColor: colorScheme.onSecondary,
// //         textStyle: textTheme.labelSmall?.copyWith(fontSize: 10),
// //       ),
// //     );
// //   }

// //   static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
// //       OutlineInputBorder(
// //         borderRadius: BorderRadius.circular(AppRadius.input),
// //         borderSide: BorderSide(color: color, width: width),
// //       );
// // }

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// import 'app_colors.dart';
// import 'app_text_styles.dart';
// import 'j_theme_extension.dart';

// /// ═══════════════════════════════════════════════════════════════
// /// Jma3a AppTheme
// /// ═══════════════════════════════════════════════════════════════
// ///
// /// Always consume via ColorScheme tokens in widgets.
// /// Never reference AppColors hex values in UI code.
// abstract final class AppTheme {
//   // ── Public constructors ────────────────────────────────────────────────
//   static ThemeData light() => _build(
//     brightness: Brightness.light,
//     colorScheme: _lightScheme,
//     jExtension: JThemeExtension.light,
//   );

//   static ThemeData dark() => _build(
//     brightness: Brightness.dark,
//     colorScheme: _darkScheme,
//     jExtension: JThemeExtension.dark,
//   );

//   // ── Light color scheme ─────────────────────────────────────────────────
//   static final _lightScheme = ColorScheme(
//     brightness: Brightness.light,

//     primary: AppColors.brandBlueDark,
//     onPrimary: AppColors.white,
//     primaryContainer: Color(0xFFDBEAFE),
//     onPrimaryContainer: AppColors.brandBlueDark,

//     secondary: AppColors.brandOrangeDark,
//     onSecondary: AppColors.white,
//     secondaryContainer: AppColors.brandOrangeLight,
//     onSecondaryContainer: AppColors.brandOrangeDark,

//     tertiary: AppColors.brandPurpleDark,
//     onTertiary: AppColors.white,
//     tertiaryContainer: AppColors.brandPurpleLight,
//     onTertiaryContainer: AppColors.brandPurpleDark,

//     error: AppColors.errorRed,
//     onError: AppColors.white,
//     errorContainer: AppColors.errorLight,
//     onErrorContainer: AppColors.errorRed,

//     surface: AppColors.neutral50,
//     onSurface: AppColors.neutral900,
//     surfaceContainerHighest: AppColors.neutral100,
//     surfaceContainerHigh: Color(0xFFECF0F7),
//     surfaceContainer: AppColors.white,
//     surfaceContainerLow: AppColors.white,
//     surfaceContainerLowest: AppColors.white,
//     onSurfaceVariant: AppColors.neutral600,

//     outline: AppColors.borderLight,
//     outlineVariant: AppColors.borderSubtle,
//     shadow: AppColors.black,
//     scrim: AppColors.black,

//     inverseSurface: AppColors.neutral900,
//     onInverseSurface: AppColors.white,
//     inversePrimary: AppColors.brandBlueElectric,
//   );

//   // ── Dark color scheme ──────────────────────────────────────────────────
//   static final _darkScheme = ColorScheme(
//     brightness: Brightness.dark,

//     primary: AppColors.brandBlueElectric,
//     onPrimary: AppColors.white,
//     primaryContainer: Color(0xFF1E3A6E),
//     onPrimaryContainer: Color(0xFF93C5FD),

//     secondary: AppColors.brandOrangeMid,
//     onSecondary: AppColors.white,
//     secondaryContainer: Color(0xFF4A1C00),
//     onSecondaryContainer: Color(0xFFFED7AA),

//     tertiary: Color(0xFF818CF8),
//     onTertiary: AppColors.white,
//     tertiaryContainer: Color(0xFF2E1065),
//     onTertiaryContainer: Color(0xFFDDD6FE),

//     error: Color(0xFFF87171),
//     onError: Color(0xFF7F1D1D),
//     errorContainer: Color(0xFF450A0A),
//     onErrorContainer: Color(0xFFFCA5A5),

//     surface: AppColors.darkBase,
//     onSurface: AppColors.neutral100,
//     surfaceContainerHighest: AppColors.darkHighest,
//     surfaceContainerHigh: AppColors.darkElevated,
//     surfaceContainer: AppColors.darkSurface,
//     surfaceContainerLow: AppColors.darkSurface,
//     surfaceContainerLowest: AppColors.darkBase,
//     onSurfaceVariant: AppColors.neutral400,

//     outline: AppColors.borderDark,
//     outlineVariant: AppColors.borderDarkSub,
//     shadow: AppColors.black,
//     scrim: AppColors.black,

//     inverseSurface: AppColors.neutral100,
//     onInverseSurface: AppColors.neutral900,
//     inversePrimary: AppColors.brandBlueDark,
//   );

//   // ── ThemeData builder ──────────────────────────────────────────────────
//   static ThemeData _build({
//     required Brightness brightness,
//     required ColorScheme colorScheme,
//     required JThemeExtension jExtension,
//   }) {
//     final isLight = brightness == Brightness.light;
//     final textTheme = AppTextStyles.textTheme(colorScheme);

//     return ThemeData(
//       useMaterial3: true,
//       brightness: brightness,
//       colorScheme: colorScheme,
//       textTheme: textTheme,
//       extensions: [jExtension],

//       // ── Scaffold ──────────────────────────────────────────────────────
//       scaffoldBackgroundColor: colorScheme.surface,

//       // ── AppBar ────────────────────────────────────────────────────────
//       appBarTheme: AppBarTheme(
//         backgroundColor: colorScheme.surface,
//         foregroundColor: colorScheme.onSurface,
//         elevation: 0,
//         scrolledUnderElevation: 0.5,
//         centerTitle: false,
//         surfaceTintColor: Colors.transparent,
//         titleTextStyle: textTheme.titleLarge?.copyWith(
//           fontWeight: FontWeight.w600,
//         ),
//         iconTheme: IconThemeData(color: colorScheme.onSurface, size: 22),
//         systemOverlayStyle: isLight
//             ? SystemUiOverlayStyle.dark.copyWith(
//                 statusBarColor: Colors.transparent,
//                 systemNavigationBarColor: colorScheme.surface,
//               )
//             : SystemUiOverlayStyle.light.copyWith(
//                 statusBarColor: Colors.transparent,
//                 systemNavigationBarColor: colorScheme.surface,
//               ),
//       ),

//       // ── Navigation bar (M3) ────────────────────────────────────────────
//       navigationBarTheme: NavigationBarThemeData(
//         backgroundColor: colorScheme.surface,
//         indicatorColor: colorScheme.primaryContainer,
//         iconTheme: WidgetStateProperty.resolveWith((states) {
//           if (states.contains(WidgetState.selected)) {
//             return IconThemeData(color: colorScheme.primary, size: 22);
//           }
//           return IconThemeData(color: colorScheme.onSurfaceVariant, size: 22);
//         }),
//         labelTextStyle: WidgetStateProperty.resolveWith((states) {
//           final selected = states.contains(WidgetState.selected);
//           return textTheme.labelSmall?.copyWith(
//             fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
//             color: selected
//                 ? colorScheme.primary
//                 : colorScheme.onSurfaceVariant,
//           );
//         }),
//         height: 64,
//         elevation: 0,
//         surfaceTintColor: Colors.transparent,
//         overlayColor: WidgetStateProperty.all(Colors.transparent),
//       ),

//       // ── Card ──────────────────────────────────────────────────────────
//       cardTheme: CardThemeData(
//         color: isLight ? AppColors.white : AppColors.darkSurface,
//         elevation: 0,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(AppRadius.card),
//           side: BorderSide(
//             color: isLight ? AppColors.borderSubtle : AppColors.borderDark,
//             width: 1,
//           ),
//         ),
//         margin: EdgeInsets.zero,
//         surfaceTintColor: Colors.transparent,
//         clipBehavior: Clip.antiAlias,
//       ),

//       // ── Elevated button ────────────────────────────────────────────────
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: colorScheme.primary,
//           foregroundColor: colorScheme.onPrimary,
//           disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.08),
//           disabledForegroundColor: colorScheme.onSurface.withOpacity(0.35),
//           elevation: 0,
//           shadowColor: Colors.transparent,
//           minimumSize: const Size(double.infinity, 52),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(AppRadius.button),
//           ),
//           textStyle: textTheme.labelLarge?.copyWith(
//             fontWeight: FontWeight.w600,
//             letterSpacing: 0.2,
//           ),
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//         ),
//       ),

//       // ── Filled button ──────────────────────────────────────────────────
//       filledButtonTheme: FilledButtonThemeData(
//         style: FilledButton.styleFrom(
//           minimumSize: const Size(double.infinity, 52),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(AppRadius.button),
//           ),
//           textStyle: textTheme.labelLarge?.copyWith(
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),

//       // ── Outlined button ────────────────────────────────────────────────
//       outlinedButtonTheme: OutlinedButtonThemeData(
//         style: OutlinedButton.styleFrom(
//           side: BorderSide(color: colorScheme.outline),
//           minimumSize: const Size(double.infinity, 52),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(AppRadius.button),
//           ),
//           textStyle: textTheme.labelLarge?.copyWith(
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),

//       // ── Text button ────────────────────────────────────────────────────
//       textButtonTheme: TextButtonThemeData(
//         style: TextButton.styleFrom(
//           foregroundColor: colorScheme.primary,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(AppRadius.sm),
//           ),
//           textStyle: textTheme.labelLarge?.copyWith(
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),

//       // ── Input ─────────────────────────────────────────────────────────
//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: isLight ? AppColors.neutral100 : AppColors.darkHighest,
//         border: _inputBorder(colorScheme.outline),
//         enabledBorder: _inputBorder(
//           isLight ? AppColors.borderSubtle : AppColors.borderDark,
//         ),
//         focusedBorder: _inputBorder(colorScheme.primary, width: 2),
//         errorBorder: _inputBorder(colorScheme.error),
//         focusedErrorBorder: _inputBorder(colorScheme.error, width: 2),
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 15,
//         ),
//         hintStyle: textTheme.bodyMedium?.copyWith(
//           color: colorScheme.onSurfaceVariant,
//         ),
//         labelStyle: textTheme.bodyMedium,
//         floatingLabelStyle: TextStyle(
//           color: colorScheme.primary,
//           fontWeight: FontWeight.w500,
//         ),
//         prefixIconColor: colorScheme.onSurfaceVariant,
//         suffixIconColor: colorScheme.onSurfaceVariant,
//       ),

//       // ── Chip ──────────────────────────────────────────────────────────
//       chipTheme: ChipThemeData(
//         backgroundColor: colorScheme.surfaceContainerHighest,
//         selectedColor: colorScheme.primaryContainer,
//         checkmarkColor: colorScheme.primary,
//         labelStyle: textTheme.labelMedium,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(AppRadius.chip),
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//         side: BorderSide.none,
//       ),

//       // ── Dialog ────────────────────────────────────────────────────────
//       dialogTheme: DialogThemeData(
//         backgroundColor: isLight ? AppColors.white : AppColors.darkSurface,
//         surfaceTintColor: Colors.transparent,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(AppRadius.dialog),
//         ),
//         elevation: 4,
//         titleTextStyle: textTheme.headlineSmall,
//         contentTextStyle: textTheme.bodyMedium,
//       ),

//       // ── Bottom sheet ──────────────────────────────────────────────────
//       bottomSheetTheme: BottomSheetThemeData(
//         backgroundColor: isLight ? AppColors.white : AppColors.darkSurface,
//         surfaceTintColor: Colors.transparent,
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(
//             top: Radius.circular(AppRadius.sheet),
//           ),
//         ),
//         elevation: 0,
//         showDragHandle: true,
//         dragHandleColor: colorScheme.onSurfaceVariant.withOpacity(0.4),
//         dragHandleSize: const Size(36, 4),
//       ),

//       // ── Divider ───────────────────────────────────────────────────────
//       dividerTheme: DividerThemeData(
//         color: colorScheme.outlineVariant,
//         thickness: 1,
//         space: 1,
//       ),

//       // ── Snack bar ─────────────────────────────────────────────────────
//       snackBarTheme: SnackBarThemeData(
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(AppRadius.md),
//         ),
//         backgroundColor: isLight
//             ? AppColors.neutral900
//             : AppColors.darkElevated,
//         contentTextStyle: textTheme.bodyMedium?.copyWith(
//           color: isLight ? AppColors.white : AppColors.neutral100,
//         ),
//         elevation: 4,
//         insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       ),

//       // ── Switch ────────────────────────────────────────────────────────
//       switchTheme: SwitchThemeData(
//         thumbColor: WidgetStateProperty.resolveWith((states) {
//           if (states.contains(WidgetState.selected)) return colorScheme.primary;
//           return colorScheme.onSurfaceVariant;
//         }),
//         trackColor: WidgetStateProperty.resolveWith((states) {
//           if (states.contains(WidgetState.selected)) {
//             return colorScheme.primaryContainer;
//           }
//           return colorScheme.surfaceContainerHighest;
//         }),
//       ),

//       // ── Progress indicator ────────────────────────────────────────────
//       progressIndicatorTheme: ProgressIndicatorThemeData(
//         color: colorScheme.primary,
//         circularTrackColor: colorScheme.surfaceContainerHighest,
//         linearTrackColor: colorScheme.surfaceContainerHighest,
//         linearMinHeight: 4,
//       ),

//       // ── List tile ─────────────────────────────────────────────────────
//       listTileTheme: ListTileThemeData(
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//         titleTextStyle: textTheme.titleSmall,
//         subtitleTextStyle: textTheme.bodySmall,
//         iconColor: colorScheme.onSurfaceVariant,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(AppRadius.md),
//         ),
//       ),

//       // ── Icon button ───────────────────────────────────────────────────
//       iconButtonTheme: IconButtonThemeData(
//         style: IconButton.styleFrom(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(AppRadius.sm),
//           ),
//         ),
//       ),

//       // ── Tab bar ───────────────────────────────────────────────────────
//       tabBarTheme: TabBarThemeData(
//         indicatorColor: colorScheme.primary,
//         labelColor: colorScheme.primary,
//         unselectedLabelColor: colorScheme.onSurfaceVariant,
//         labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
//         unselectedLabelStyle: textTheme.labelLarge,
//         dividerColor: colorScheme.outlineVariant,
//         indicatorSize: TabBarIndicatorSize.label,
//         overlayColor: WidgetStateProperty.all(Colors.transparent),
//       ),

//       // ── Slider ────────────────────────────────────────────────────────
//       sliderTheme: SliderThemeData(
//         activeTrackColor: colorScheme.primary,
//         inactiveTrackColor: colorScheme.surfaceContainerHighest,
//         thumbColor: colorScheme.primary,
//         overlayColor: colorScheme.primary.withOpacity(0.1),
//         trackHeight: 4,
//       ),

//       // ── Popup menu ────────────────────────────────────────────────────
//       popupMenuTheme: PopupMenuThemeData(
//         color: isLight ? AppColors.white : AppColors.darkElevated,
//         surfaceTintColor: Colors.transparent,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(AppRadius.md),
//         ),
//         elevation: 8,
//         textStyle: textTheme.bodyMedium,
//         shadowColor: AppColors.black.withOpacity(0.2),
//       ),

//       // ── Tooltip ───────────────────────────────────────────────────────
//       tooltipTheme: TooltipThemeData(
//         decoration: BoxDecoration(
//           color: isLight ? AppColors.neutral900 : AppColors.darkElevated,
//           borderRadius: BorderRadius.circular(AppRadius.sm),
//         ),
//         textStyle: textTheme.labelSmall?.copyWith(
//           color: isLight ? AppColors.white : AppColors.neutral100,
//         ),
//       ),

//       // ── Search bar ────────────────────────────────────────────────────
//       searchBarTheme: SearchBarThemeData(
//         backgroundColor: WidgetStateProperty.all(
//           isLight ? AppColors.neutral100 : AppColors.darkHighest,
//         ),
//         surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
//         elevation: WidgetStateProperty.all(0),
//         shape: WidgetStateProperty.all(
//           RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(AppRadius.button),
//           ),
//         ),
//         textStyle: WidgetStateProperty.all(textTheme.bodyMedium),
//         hintStyle: WidgetStateProperty.all(
//           textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
//         ),
//       ),

//       // ── Badge ─────────────────────────────────────────────────────────
//       badgeTheme: BadgeThemeData(
//         backgroundColor: colorScheme.secondary,
//         textColor: colorScheme.onSecondary,
//         textStyle: textTheme.labelSmall?.copyWith(fontSize: 10),
//       ),
//     );
//   }

//   static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
//       OutlineInputBorder(
//         borderRadius: BorderRadius.circular(AppRadius.input),
//         borderSide: BorderSide(color: color, width: width),
//       );
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'j_theme_extension.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(
    brightness: Brightness.light,
    colorScheme: _lightScheme,
    jExtension: JThemeExtension.light,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    colorScheme: _darkScheme,
    jExtension: JThemeExtension.dark,
  );

  static final _lightScheme = ColorScheme(
    brightness: Brightness.light,

    primary: AppColors.brandBlueDark,
    onPrimary: AppColors.white,
    primaryContainer: Color(0xFFDBEAFE),
    onPrimaryContainer: AppColors.brandBlueDark,

    secondary: AppColors.brandOrangeDark,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.brandOrangeLight,
    onSecondaryContainer: AppColors.brandOrangeDark,

    tertiary: AppColors.brandPurpleDark,
    onTertiary: AppColors.white,
    tertiaryContainer: AppColors.brandPurpleLight,
    onTertiaryContainer: AppColors.brandPurpleDark,

    error: AppColors.errorRed,
    onError: AppColors.white,
    errorContainer: AppColors.errorLight,
    onErrorContainer: AppColors.errorRed,

    surface: AppColors.neutral50,
    onSurface: AppColors.neutral900,
    surfaceContainerHighest: AppColors.neutral100,
    surfaceContainerHigh: Color(0xFFECF0F7),
    surfaceContainer: AppColors.white,
    surfaceContainerLow: AppColors.white,
    surfaceContainerLowest: AppColors.white,
    onSurfaceVariant: AppColors.neutral600,

    outline: AppColors.borderLight,
    outlineVariant: AppColors.borderSubtle,
    shadow: AppColors.black,
    scrim: AppColors.black,

    inverseSurface: AppColors.neutral900,
    onInverseSurface: AppColors.white,
    inversePrimary: AppColors.brandBlueElectric,
  );

  static final _darkScheme = ColorScheme(
    brightness: Brightness.dark,

    primary: AppColors.brandBlueElectric,
    onPrimary: AppColors.white,
    primaryContainer: Color(0xFF1E3A6E),
    onPrimaryContainer: Color(0xFF93C5FD),

    secondary: AppColors.brandOrangeMid,
    onSecondary: AppColors.white,
    secondaryContainer: Color(0xFF4A1C00),
    onSecondaryContainer: Color(0xFFFED7AA),

    tertiary: Color(0xFF818CF8),
    onTertiary: AppColors.white,
    tertiaryContainer: Color(0xFF2E1065),
    onTertiaryContainer: Color(0xFFDDD6FE),

    error: Color(0xFFF87171),
    onError: Color(0xFF7F1D1D),
    errorContainer: Color(0xFF450A0A),
    onErrorContainer: Color(0xFFFCA5A5),

    surface: AppColors.darkBase,
    onSurface: AppColors.neutral100,
    surfaceContainerHighest: AppColors.darkHighest,
    surfaceContainerHigh: AppColors.darkElevated,
    surfaceContainer: AppColors.darkSurface,
    surfaceContainerLow: AppColors.darkSurface,
    surfaceContainerLowest: AppColors.darkBase,
    onSurfaceVariant: AppColors.neutral400,

    outline: AppColors.borderDark,
    outlineVariant: AppColors.borderDarkSub,
    shadow: AppColors.black,
    scrim: AppColors.black,

    inverseSurface: AppColors.neutral100,
    onInverseSurface: AppColors.neutral900,
    inversePrimary: AppColors.brandBlueDark,
  );

  static ThemeData withPrimary(
    Color primary,
    Brightness brightness, {
    Color? backgroundOverride,
  }) {
    final isLight = brightness == Brightness.light;
    final base = isLight ? _lightScheme : _darkScheme;
    // Premium background-color customization: when set, this replaces the
    // theme's fixed surface family (surface/surfaceContainer*/onSurface/
    // outline/inverseSurface) with tones derived from the user's chosen
    // color, while primary/secondary/tertiary/error stay exactly as the
    // theme defines them — preserving the selected theme's own accent
    // identity instead of flattening it.
    final surfaceFamily = backgroundOverride != null
        ? _deriveSurfaceFamily(backgroundOverride)
        : null;
    final effectiveSurface = surfaceFamily?.surface ?? base.surface;
    final customScheme = base.copyWith(
      primary: primary,
      onPrimary: _contrastColor(primary),
      primaryContainer: Color.alphaBlend(
        primary.withOpacity(0.15),
        effectiveSurface,
      ),
      onPrimaryContainer: primary,
      inversePrimary: primary.withOpacity(0.7),
      surface: surfaceFamily?.surface,
      surfaceContainerLowest: surfaceFamily?.containerLowest,
      surfaceContainerLow: surfaceFamily?.containerLow,
      surfaceContainer: surfaceFamily?.container,
      surfaceContainerHigh: surfaceFamily?.containerHigh,
      surfaceContainerHighest: surfaceFamily?.containerHighest,
      onSurface: surfaceFamily?.onSurface,
      onSurfaceVariant: surfaceFamily?.onSurfaceVariant,
      outline: surfaceFamily?.outline,
      outlineVariant: surfaceFamily?.outlineVariant,
      inverseSurface: surfaceFamily?.inverseSurface,
      onInverseSurface: surfaceFamily?.onInverseSurface,
    );
    return _build(
      brightness: brightness,
      colorScheme: customScheme,
      jExtension: isLight ? JThemeExtension.light : JThemeExtension.dark,
    );
  }

  static Color _contrastColor(Color c) {
    return c.computeLuminance() > 0.35
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFFFFFFF);
  }

  /// Derives a full surface family (background + 5 tonal container steps +
  /// on-colors + outlines) from an arbitrary user-chosen background color.
  /// Direction is driven by the CHOSEN color's own computed luminance, not
  /// the theme's declared [Brightness] — a user can pick a pale background
  /// while in dark mode (or vice versa), and deriving tiers from the
  /// theme's Brightness would blend toward the wrong pole for that
  /// combination. Container tiers step 0/4/8/12/16% toward the contrast
  /// color, matching Material 3's monotonic tonal-step direction
  /// generalized to an arbitrary seed.
  static _SurfaceFamily _deriveSurfaceFamily(Color background) {
    final ink = _contrastColor(background);
    Color blend(double pct) => Color.alphaBlend(ink.withOpacity(pct), background);
    return _SurfaceFamily(
      surface: background,
      containerLowest: background,
      containerLow: blend(0.04),
      container: blend(0.08),
      containerHigh: blend(0.12),
      containerHighest: blend(0.16),
      onSurface: ink,
      onSurfaceVariant: blend(0.45),
      outline: blend(0.30),
      outlineVariant: blend(0.12),
      inverseSurface: ink,
      onInverseSurface: _contrastColor(ink),
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required JThemeExtension jExtension,
  }) {
    final isLight = brightness == Brightness.light;
    final textTheme = AppTextStyles.textTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      extensions: [jExtension],

      scaffoldBackgroundColor: colorScheme.surface,

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface, size: 22),
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: colorScheme.surface,
              )
            : SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: colorScheme.surface,
              ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 22);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
        height: 64,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),

      cardTheme: CardThemeData(
        color: isLight ? AppColors.white : AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: isLight ? AppColors.borderSubtle : AppColors.borderDark,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.08),
          disabledForegroundColor: colorScheme.onSurface.withOpacity(0.35),
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.outline),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? AppColors.neutral100 : AppColors.darkHighest,
        border: _inputBorder(colorScheme.outline),
        enabledBorder: _inputBorder(
          isLight ? AppColors.borderSubtle : AppColors.borderDark,
        ),
        focusedBorder: _inputBorder(colorScheme.primary, width: 2),
        errorBorder: _inputBorder(colorScheme.error),
        focusedErrorBorder: _inputBorder(colorScheme.error, width: 2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyMedium,
        floatingLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        checkmarkColor: colorScheme.primary,
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        side: BorderSide.none,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? AppColors.white : AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        elevation: 4,
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isLight ? AppColors.white : AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        elevation: 0,
        // Deliberately false, not the historical `true`. Flutter's
        // BottomSheet.build() wraps content in an extra Stack + Padding(48)
        // + a Semantics(button: true) drag handle whenever this resolves
        // true, unconditionally for every showModalBottomSheet call in the
        // app that doesn't override it per-call. That extra structure was
        // confirmed (via a from-scratch layout audit, not local to any one
        // screen) to reproduce across every bottom sheet regardless of
        // content — including a bare placeholder Container — and to
        // specifically interact with an active screen reader walking the
        // newly-introduced interactive semantics node mid-layout, producing
        // '!_debugDoingThisLayout' / semantics.parentDataDirty crashes.
        // Individual sheets that want the drag-handle affordance can still
        // opt in by passing showDragHandle: true to their own
        // showModalBottomSheet call — this only changes the app-wide
        // default.
        showDragHandle: false,
        dragHandleColor: colorScheme.onSurfaceVariant.withOpacity(0.4),
        dragHandleSize: const Size(36, 4),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        backgroundColor: isLight
            ? AppColors.neutral900
            : AppColors.darkElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isLight ? AppColors.white : AppColors.neutral100,
        ),
        elevation: 4,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colorScheme.surfaceContainerHighest,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        linearMinHeight: 4,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        iconColor: colorScheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        indicatorColor: colorScheme.primary,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.labelLarge,
        dividerColor: colorScheme.outlineVariant,
        indicatorSize: TabBarIndicatorSize.label,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.1),
        trackHeight: 4,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: isLight ? AppColors.white : AppColors.darkElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 8,
        textStyle: textTheme.bodyMedium,
        shadowColor: AppColors.black.withOpacity(0.2),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isLight ? AppColors.neutral900 : AppColors.darkElevated,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: textTheme.labelSmall?.copyWith(
          color: isLight ? AppColors.white : AppColors.neutral100,
        ),
      ),

      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(
          isLight ? AppColors.neutral100 : AppColors.darkHighest,
        ),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        textStyle: WidgetStateProperty.all(textTheme.bodyMedium),
        hintStyle: WidgetStateProperty.all(
          textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),

      badgeTheme: BadgeThemeData(
        backgroundColor: colorScheme.secondary,
        textColor: colorScheme.onSecondary,
        textStyle: textTheme.labelSmall?.copyWith(fontSize: 10),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(color: color, width: width),
      );
}

/// Output of [AppTheme._deriveSurfaceFamily] — every ColorScheme field that
/// makes up the "surface" side of the theme (as opposed to primary/
/// secondary/tertiary, which stay theme-defined and untouched).
class _SurfaceFamily {
  const _SurfaceFamily({
    required this.surface,
    required this.containerLowest,
    required this.containerLow,
    required this.container,
    required this.containerHigh,
    required this.containerHighest,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.inverseSurface,
    required this.onInverseSurface,
  });

  final Color surface;
  final Color containerLowest;
  final Color containerLow;
  final Color container;
  final Color containerHigh;
  final Color containerHighest;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color inverseSurface;
  final Color onInverseSurface;
}
