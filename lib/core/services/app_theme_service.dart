// // // // import 'package:flutter/material.dart';
// // // // import 'package:shared_preferences/shared_preferences.dart';

// // // // /// A named theme with a seed color and optional dark mode.
// // // // class AppThemeData {
// // // //   const AppThemeData({
// // // //     required this.id,
// // // //     required this.name,
// // // //     required this.seed,
// // // //     this.isPremium = false,
// // // //     this.isPremiumPlus = false,
// // // //     this.emoji = '',
// // // //   });
// // // //   final String id;
// // // //   final String name;
// // // //   final Color seed;
// // // //   final bool isPremium;
// // // //   final bool isPremiumPlus;
// // // //   final String emoji;

// // // //   ThemeData toTheme(Brightness brightness) => ThemeData(
// // // //     useMaterial3: true,
// // // //     brightness: brightness,
// // // //     colorSchemeSeed: seed,
// // // //   );
// // // // }

// // // // class AppThemeService extends ChangeNotifier {
// // // //   AppThemeService._();
// // // //   static final AppThemeService instance = AppThemeService._();

// // // //   static const _prefKey = 'app_theme_id';
// // // //   static const _darkKey = 'app_theme_dark';

// // // //   String _currentId = 'default';
// // // //   bool _isDark = false;

// // // //   String get currentId => _currentId;
// // // //   bool get isDark => _isDark;

// // // //   static const List<AppThemeData> allThemes = [
// // // //     AppThemeData(
// // // //       id: 'default',
// // // //       name: 'Jma3a',
// // // //       seed: Color(0xFF6C63FF),
// // // //       emoji: '🎮',
// // // //     ),
// // // //     AppThemeData(
// // // //       id: 'midnight',
// // // //       name: 'Midnight',
// // // //       seed: Color(0xFF1A237E),
// // // //       emoji: '🌙',
// // // //       isPremium: true,
// // // //     ),
// // // //     AppThemeData(
// // // //       id: 'rose',
// // // //       name: 'Rose',
// // // //       seed: Color(0xFFE91E63),
// // // //       emoji: '🌹',
// // // //       isPremium: true,
// // // //     ),
// // // //     AppThemeData(
// // // //       id: 'ocean',
// // // //       name: 'Ocean',
// // // //       seed: Color(0xFF006994),
// // // //       emoji: '🌊',
// // // //       isPremium: true,
// // // //     ),
// // // //     AppThemeData(
// // // //       id: 'forest',
// // // //       name: 'Forest',
// // // //       seed: Color(0xFF2E7D32),
// // // //       emoji: '🌲',
// // // //       isPremium: true,
// // // //     ),
// // // //     AppThemeData(
// // // //       id: 'sunset',
// // // //       name: 'Sunset',
// // // //       seed: Color(0xFFFF6B35),
// // // //       emoji: '🌅',
// // // //       isPremium: true,
// // // //     ),
// // // //     AppThemeData(
// // // //       id: 'galaxy',
// // // //       name: 'Galaxy',
// // // //       seed: Color(0xFF4A148C),
// // // //       emoji: '🌌',
// // // //       isPremiumPlus: true,
// // // //     ),
// // // //     AppThemeData(
// // // //       id: 'gold',
// // // //       name: 'Gold',
// // // //       seed: Color(0xFFF57F17),
// // // //       emoji: '✨',
// // // //       isPremiumPlus: true,
// // // //     ),
// // // //     AppThemeData(
// // // //       id: 'neon',
// // // //       name: 'Neon',
// // // //       seed: Color(0xFF00E5FF),
// // // //       emoji: '⚡',
// // // //       isPremiumPlus: true,
// // // //     ),
// // // //   ];

// // // //   AppThemeData get current => allThemes.firstWhere(
// // // //     (t) => t.id == _currentId,
// // // //     orElse: () => allThemes.first,
// // // //   );

// // // //   ThemeData get lightTheme => current.toTheme(Brightness.light);
// // // //   ThemeData get darkTheme => current.toTheme(Brightness.dark);
// // // //   ThemeMode get themeMode => isDark ? ThemeMode.dark : ThemeMode.light;

// // // //   Future<void> load() async {
// // // //     final prefs = await SharedPreferences.getInstance();
// // // //     _currentId = prefs.getString(_prefKey) ?? 'default';
// // // //     _isDark = prefs.getBool(_darkKey) ?? false;
// // // //     notifyListeners();
// // // //   }

// // // //   Future<void> setTheme(
// // // //     String id, {
// // // //     required bool isPremiumActive,
// // // //     required bool isPremiumPlus,
// // // //   }) async {
// // // //     final theme = allThemes.firstWhere(
// // // //       (t) => t.id == id,
// // // //       orElse: () => allThemes.first,
// // // //     );
// // // //     if (theme.isPremiumPlus && !isPremiumPlus) return;
// // // //     if (theme.isPremium && !isPremiumActive) return;
// // // //     _currentId = id;
// // // //     final prefs = await SharedPreferences.getInstance();
// // // //     await prefs.setString(_prefKey, id);
// // // //     notifyListeners();
// // // //   }

// // // //   Future<void> toggleDark() async {
// // // //     _isDark = !_isDark;
// // // //     final prefs = await SharedPreferences.getInstance();
// // // //     await prefs.setBool(_darkKey, _isDark);
// // // //     notifyListeners();
// // // //   }

// // // //   List<AppThemeData> availableFor({
// // // //     required bool isPremium,
// // // //     required bool isPremiumPlus,
// // // //   }) => allThemes.where((t) {
// // // //     if (t.isPremiumPlus) return isPremiumPlus;
// // // //     if (t.isPremium) return isPremium;
// // // //     return true;
// // // //   }).toList();
// // // // }

// // // import 'package:flutter/material.dart';
// // // import 'package:shared_preferences/shared_preferences.dart';

// // // import '../theme/app_theme.dart';

// // // class AppThemeData {
// // //   const AppThemeData({
// // //     required this.id,
// // //     required this.name,
// // //     required this.emoji,
// // //     required this.seed,
// // //     required this.primaryLight,
// // //     required this.primaryDark,
// // //     this.isPremium = false,
// // //     this.isPremiumPlus = false,
// // //   });
// // //   final String id, name, emoji;
// // //   final Color primaryLight;
// // //   final Color primaryDark;
// // //   final Color seed;
// // //   final bool isPremium, isPremiumPlus;

// // //   ThemeData buildTheme(Brightness brightness) {
// // //     final base = brightness == Brightness.light
// // //         ? AppTheme.light()
// // //         : AppTheme.dark();
// // //     final primary = brightness == Brightness.light ? primaryLight : primaryDark;
// // //     final baseScheme = base.colorScheme;
// // //     return base.copyWith(
// // //       colorScheme: baseScheme.copyWith(
// // //         primary: primary,
// // //         onPrimary: baseScheme.onPrimary,
// // //         primaryContainer: primary.withOpacity(0.15),
// // //         onPrimaryContainer: primary,
// // //         inversePrimary: primary.withOpacity(0.7),
// // //       ),
// // //     );
// // //   }
// // // }

// // // class AppThemeService extends ChangeNotifier {
// // //   AppThemeService._();
// // //   static final AppThemeService instance = AppThemeService._();

// // //   static const _prefKey = 'app_theme_id_v2';
// // //   static const _darkKey = 'app_theme_dark_v2';

// // //   String _currentId = 'jma3a';
// // //   bool _isDark = false;

// // //   String get currentId => _currentId;
// // //   bool get isDark => _isDark;

// // //   static const List<AppThemeData> allThemes = [
// // //     AppThemeData(
// // //       id: 'jma3a',
// // //       name: 'Jma3a',
// // //       emoji: '🎮',
// // //       seed: Color(0xFF6C63FF),
// // //       primaryLight: Color(0xFF1D4ED8),
// // //       primaryDark: Color(0xFF60A5FA),
// // //     ),
// // //     AppThemeData(
// // //       id: 'midnight',
// // //       name: 'Midnight',
// // //       emoji: '🌙',
// // //       seed: Color(0xFF6C63FF),
// // //       primaryLight: Color(0xFF1E40AF),
// // //       primaryDark: Color(0xFF93C5FD),
// // //     ),
// // //     AppThemeData(
// // //       id: 'slate',
// // //       name: 'Classic',
// // //       emoji: '🎨',
// // //       seed: Color(0xFF6C63FF),
// // //       primaryLight: Color(0xFF334155),
// // //       primaryDark: Color(0xFF94A3B8),
// // //     ),
// // //     AppThemeData(
// // //       id: 'candy',
// // //       name: 'Candy',
// // //       emoji: '🍬',
// // //       seed: Color(0xFF6C63FF),
// // //       primaryLight: Color(0xFFBE185D),
// // //       primaryDark: Color(0xFFF472B6),
// // //       isPremium: true,
// // //     ),
// // //     AppThemeData(
// // //       id: 'ocean',
// // //       name: 'Ocean',
// // //       emoji: '🌊',
// // //       seed: Color(0xFF6C63FF),
// // //       primaryLight: Color(0xFF0369A1),
// // //       primaryDark: Color(0xFF38BDF8),
// // //       isPremium: true,
// // //     ),
// // //     AppThemeData(
// // //       id: 'forest',
// // //       name: 'Forest',
// // //       emoji: '🌲',
// // //       seed: Color(0xFF6C63FF),
// // //       primaryLight: Color(0xFF166534),
// // //       primaryDark: Color(0xFF4ADE80),
// // //       isPremium: true,
// // //     ),
// // //     AppThemeData(
// // //       id: 'sunset',
// // //       name: 'Sunset',
// // //       emoji: '🌅',
// // //       seed: Color(0xFF6C63FF),
// // //       primaryLight: Color(0xFFEA580C),
// // //       primaryDark: Color(0xFFFB923C),
// // //       isPremium: true,
// // //     ),
// // //     AppThemeData(
// // //       id: 'lavender',
// // //       name: 'Lavender',
// // //       emoji: '💜',
// // //       seed: Color(0xFF6C63FF),
// // //       primaryLight: Color(0xFF7C3AED),
// // //       primaryDark: Color(0xFFA78BFA),
// // //       isPremium: true,
// // //     ),
// // //     AppThemeData(
// // //       id: 'rose',
// // //       name: 'Rose',
// // //       emoji: '🌹',
// // //       seed: Color(0xFF6C63FF),
// // //       primaryLight: Color(0xFFBE123C),
// // //       primaryDark: Color(0xFFFB7185),
// // //       isPremium: true,
// // //     ),
// // //     AppThemeData(
// // //       id: 'galaxy',
// // //       name: 'Galaxy',
// // //       emoji: '🌌',
// // //       seed: Color(0xFF6C63FF),
// // //       primaryLight: Color(0xFF6D28D9),
// // //       primaryDark: Color(0xFFC4B5FD),
// // //       isPremiumPlus: true,
// // //     ),
// // //     AppThemeData(
// // //       id: 'neon',
// // //       name: 'Neon',
// // //       emoji: '⚡',
// // //       seed: Color(0xFF6C63FF),
// // //       primaryLight: Color(0xFF0891B2),
// // //       primaryDark: Color(0xFF22D3EE),
// // //       isPremiumPlus: true,
// // //     ),
// // //     AppThemeData(
// // //       id: 'gold',
// // //       name: 'Gold',
// // //       emoji: '✨',
// // //       seed: Color(0xFF6C63FF),
// // //       primaryLight: Color(0xFFB45309),
// // //       primaryDark: Color(0xFFFBBF24),
// // //       isPremiumPlus: true,
// // //     ),
// // //     AppThemeData(
// // //       id: 'cyber',
// // //       name: 'Cyber',
// // //       emoji: '🤖',
// // //       seed: Color(0xFF6C63FF),
// // //       primaryLight: Color(0xFF047857),
// // //       primaryDark: Color(0xFF34D399),
// // //       isPremiumPlus: true,
// // //     ),
// // //     AppThemeData(
// // //       id: 'lava',
// // //       name: 'Lava',
// // //       emoji: '🌋',
// // //       seed: Color(0xFF6C63FF),
// // //       primaryLight: Color(0xFFB91C1C),
// // //       primaryDark: Color(0xFFF87171),
// // //       isPremiumPlus: true,
// // //     ),
// // //     AppThemeData(
// // //       id: 'aurora',
// // //       name: 'Aurora',
// // //       emoji: '🌈',
// // //       seed: Color(0xFF6C63FF),
// // //       primaryLight: Color(0xFF0F766E),
// // //       primaryDark: Color(0xFF2DD4BF),
// // //       isPremiumPlus: true,
// // //     ),
// // //   ];

// // //   AppThemeData get current => allThemes.firstWhere(
// // //     (t) => t.id == _currentId,
// // //     orElse: () => allThemes.first,
// // //   );

// // //   ThemeData get lightTheme => current.buildTheme(Brightness.light);
// // //   ThemeData get darkTheme => current.buildTheme(Brightness.dark);
// // //   ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

// // //   Future<void> load() async {
// // //     final prefs = await SharedPreferences.getInstance();
// // //     _currentId = prefs.getString(_prefKey) ?? 'jma3a';
// // //     _isDark = prefs.getBool(_darkKey) ?? false;
// // //     notifyListeners();
// // //   }

// // //   Future<void> setTheme(
// // //     String id, {
// // //     required bool isPremiumActive,
// // //     required bool isPremiumPlus,
// // //   }) async {
// // //     final t = allThemes.firstWhere(
// // //       (t) => t.id == id,
// // //       orElse: () => allThemes.first,
// // //     );
// // //     if (t.isPremiumPlus && !isPremiumPlus) return;
// // //     if (t.isPremium && !isPremiumActive) return;
// // //     _currentId = id;
// // //     final prefs = await SharedPreferences.getInstance();
// // //     await prefs.setString(_prefKey, id);
// // //     notifyListeners();
// // //   }

// // //   Future<void> toggleDark() async {
// // //     _isDark = !_isDark;
// // //     final prefs = await SharedPreferences.getInstance();
// // //     await prefs.setBool(_darkKey, _isDark);
// // //     notifyListeners();
// // //   }

// // //   List<AppThemeData> availableFor({
// // //     required bool isPremium,
// // //     required bool isPremiumPlus,
// // //   }) => allThemes.where((t) {
// // //     if (t.isPremiumPlus) return isPremiumPlus;
// // //     if (t.isPremium) return isPremium;
// // //     return true;
// // //   }).toList();
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:shared_preferences/shared_preferences.dart';

// // import '../theme/app_theme.dart';

// // class AppThemeData {
// //   const AppThemeData({
// //     required this.id,
// //     required this.name,
// //     required this.emoji,
// //     required this.primaryLight,
// //     required this.primaryDark,
// //     this.isPremium = false,
// //     this.isPremiumPlus = false,
// //   });
// //   final String id, name, emoji;
// //   final Color primaryLight;
// //   final Color primaryDark;
// //   final bool isPremium, isPremiumPlus;

// //   ThemeData buildTheme(Brightness brightness) {
// //     final base = brightness == Brightness.light
// //         ? AppTheme.light()
// //         : AppTheme.dark();
// //     final primary = brightness == Brightness.light ? primaryLight : primaryDark;
// //     final baseScheme = base.colorScheme;
// //     return base.copyWith(
// //       colorScheme: baseScheme.copyWith(
// //         primary: primary,
// //         onPrimary: baseScheme.onPrimary,
// //         primaryContainer: primary.withOpacity(0.15),
// //         onPrimaryContainer: primary,
// //         inversePrimary: primary.withOpacity(0.7),
// //       ),
// //     );
// //   }
// // }

// // class AppThemeService extends ChangeNotifier {
// //   AppThemeService._();
// //   static final AppThemeService instance = AppThemeService._();

// //   static const _prefKey = 'app_theme_id_v2';
// //   static const _darkKey = 'app_theme_dark_v2';

// //   String _currentId = 'jma3a';
// //   ThemeMode _themeMode = ThemeMode.system;

// //   String get currentId => _currentId;
// //   ThemeMode get themeMode => _themeMode;
// //   bool get isDark => _themeMode == ThemeMode.dark;

// //   static const List<AppThemeData> allThemes = [
// //     AppThemeData(
// //       id: 'jma3a',
// //       name: 'Jma3a',
// //       emoji: '🎮',
// //       primaryLight: Color(0xFF1D4ED8),
// //       primaryDark: Color(0xFF60A5FA),
// //     ),
// //     AppThemeData(
// //       id: 'midnight',
// //       name: 'Midnight',
// //       emoji: '🌙',
// //       primaryLight: Color(0xFF1E40AF),
// //       primaryDark: Color(0xFF93C5FD),
// //     ),
// //     AppThemeData(
// //       id: 'slate',
// //       name: 'Classic',
// //       emoji: '🎨',
// //       primaryLight: Color(0xFF334155),
// //       primaryDark: Color(0xFF94A3B8),
// //     ),
// //     AppThemeData(
// //       id: 'candy',
// //       name: 'Candy',
// //       emoji: '🍬',
// //       primaryLight: Color(0xFFBE185D),
// //       primaryDark: Color(0xFFF472B6),
// //       isPremium: true,
// //     ),
// //     AppThemeData(
// //       id: 'ocean',
// //       name: 'Ocean',
// //       emoji: '🌊',
// //       primaryLight: Color(0xFF0369A1),
// //       primaryDark: Color(0xFF38BDF8),
// //       isPremium: true,
// //     ),
// //     AppThemeData(
// //       id: 'forest',
// //       name: 'Forest',
// //       emoji: '🌲',
// //       primaryLight: Color(0xFF166534),
// //       primaryDark: Color(0xFF4ADE80),
// //       isPremium: true,
// //     ),
// //     AppThemeData(
// //       id: 'sunset',
// //       name: 'Sunset',
// //       emoji: '🌅',
// //       primaryLight: Color(0xFFEA580C),
// //       primaryDark: Color(0xFFFB923C),
// //       isPremium: true,
// //     ),
// //     AppThemeData(
// //       id: 'lavender',
// //       name: 'Lavender',
// //       emoji: '💜',
// //       primaryLight: Color(0xFF7C3AED),
// //       primaryDark: Color(0xFFA78BFA),
// //       isPremium: true,
// //     ),
// //     AppThemeData(
// //       id: 'rose',
// //       name: 'Rose',
// //       emoji: '🌹',
// //       primaryLight: Color(0xFFBE123C),
// //       primaryDark: Color(0xFFFB7185),
// //       isPremium: true,
// //     ),
// //     AppThemeData(
// //       id: 'galaxy',
// //       name: 'Galaxy',
// //       emoji: '🌌',
// //       primaryLight: Color(0xFF6D28D9),
// //       primaryDark: Color(0xFFC4B5FD),
// //       isPremiumPlus: true,
// //     ),
// //     AppThemeData(
// //       id: 'neon',
// //       name: 'Neon',
// //       emoji: '⚡',
// //       primaryLight: Color(0xFF0891B2),
// //       primaryDark: Color(0xFF22D3EE),
// //       isPremiumPlus: true,
// //     ),
// //     AppThemeData(
// //       id: 'gold',
// //       name: 'Gold',
// //       emoji: '✨',
// //       primaryLight: Color(0xFFB45309),
// //       primaryDark: Color(0xFFFBBF24),
// //       isPremiumPlus: true,
// //     ),
// //     AppThemeData(
// //       id: 'cyber',
// //       name: 'Cyber',
// //       emoji: '🤖',
// //       primaryLight: Color(0xFF047857),
// //       primaryDark: Color(0xFF34D399),
// //       isPremiumPlus: true,
// //     ),
// //     AppThemeData(
// //       id: 'lava',
// //       name: 'Lava',
// //       emoji: '🌋',
// //       primaryLight: Color(0xFFB91C1C),
// //       primaryDark: Color(0xFFF87171),
// //       isPremiumPlus: true,
// //     ),
// //     AppThemeData(
// //       id: 'aurora',
// //       name: 'Aurora',
// //       emoji: '🌈',
// //       primaryLight: Color(0xFF0F766E),
// //       primaryDark: Color(0xFF2DD4BF),
// //       isPremiumPlus: true,
// //     ),
// //   ];

// //   AppThemeData get current => allThemes.firstWhere(
// //     (t) => t.id == _currentId,
// //     orElse: () => allThemes.first,
// //   );

// //   ThemeData get lightTheme => current.buildTheme(Brightness.light);
// //   ThemeData get darkTheme => current.buildTheme(Brightness.dark);

// //   Future<void> load() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     _currentId = prefs.getString(_prefKey) ?? 'jma3a';
// //     final modeStr = prefs.getString(_darkKey) ?? 'system';
// //     _themeMode = switch (modeStr) {
// //       'light' => ThemeMode.light,
// //       'dark' => ThemeMode.dark,
// //       _ => ThemeMode.system,
// //     };
// //     notifyListeners();
// //   }

// //   Future<void> setThemeMode(ThemeMode mode) async {
// //     _themeMode = mode;
// //     final prefs = await SharedPreferences.getInstance();
// //     final str = switch (mode) {
// //       ThemeMode.light => 'light',
// //       ThemeMode.dark => 'dark',
// //       ThemeMode.system => 'system',
// //     };
// //     await prefs.setString(_darkKey, str);
// //     notifyListeners();
// //   }

// //   Future<void> toggleDark() async {
// //     final next = _themeMode == ThemeMode.dark
// //         ? ThemeMode.light
// //         : ThemeMode.dark;
// //     await setThemeMode(next);
// //   }

// //   Future<void> setTheme(
// //     String id, {
// //     required bool isPremiumActive,
// //     required bool isPremiumPlus,
// //   }) async {
// //     final t = allThemes.firstWhere(
// //       (t) => t.id == id,
// //       orElse: () => allThemes.first,
// //     );
// //     if (t.isPremiumPlus && !isPremiumPlus) return;
// //     if (t.isPremium && !isPremiumActive) return;
// //     _currentId = id;
// //     final prefs = await SharedPreferences.getInstance();
// //     await prefs.setString(_prefKey, id);
// //     notifyListeners();
// //   }

// //   List<AppThemeData> availableFor({
// //     required bool isPremium,
// //     required bool isPremiumPlus,
// //   }) => allThemes.where((t) {
// //     if (t.isPremiumPlus) return isPremiumPlus;
// //     if (t.isPremium) return isPremium;
// //     return true;
// //   }).toList();
// // }

// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../theme/app_theme.dart';

// class AppThemeData {
//   const AppThemeData({
//     required this.id,
//     required this.name,
//     required this.emoji,
//     required this.primaryLight,
//     required this.primaryDark,
//     this.isPremium = false,
//     this.isPremiumPlus = false,
//     this.playfulBackground = false,
//   });
//   final String id, name, emoji;
//   final Color primaryLight;
//   final Color primaryDark;
//   final bool isPremium;
//   final bool isPremiumPlus;
//   final bool playfulBackground;

//   ThemeData buildTheme(Brightness brightness) => AppTheme.withPrimary(
//     brightness == Brightness.light ? primaryLight : primaryDark,
//     brightness,
//   );
// }

// class AppThemeService extends ChangeNotifier {
//   AppThemeService._();
//   static final AppThemeService instance = AppThemeService._();

//   static const _prefKey = 'app_theme_id_v2';
//   static const _darkKey = 'app_theme_dark_v2';

//   String _currentId = 'jma3a';
//   ThemeMode _themeMode = ThemeMode.system;

//   String get currentId => _currentId;
//   ThemeMode get themeMode => _themeMode;
//   bool get isDark => _themeMode == ThemeMode.dark;

//   static const List<AppThemeData> allThemes = [
//     AppThemeData(
//       id: 'jma3a',
//       name: 'Jma3a',
//       emoji: '🎮',
//       primaryLight: Color(0xFF1D4ED8),
//       primaryDark: Color(0xFF60A5FA),
//     ),
//     AppThemeData(
//       id: 'midnight',
//       name: 'Midnight',
//       emoji: '🌙',
//       primaryLight: Color(0xFF1E40AF),
//       primaryDark: Color(0xFF93C5FD),
//     ),
//     AppThemeData(
//       id: 'slate',
//       name: 'Classic',
//       emoji: '🎨',
//       primaryLight: Color(0xFF334155),
//       primaryDark: Color(0xFF94A3B8),
//     ),
//     AppThemeData(
//       id: 'candy',
//       name: 'Candy',
//       emoji: '🍬',
//       primaryLight: Color(0xFFBE185D),
//       primaryDark: Color(0xFFF472B6),
//       isPremium: true,
//     ),
//     AppThemeData(
//       id: 'ocean',
//       name: 'Ocean',
//       emoji: '🌊',
//       primaryLight: Color(0xFF0369A1),
//       primaryDark: Color(0xFF38BDF8),
//       isPremium: true,
//     ),
//     AppThemeData(
//       id: 'forest',
//       name: 'Forest',
//       emoji: '🌲',
//       primaryLight: Color(0xFF166534),
//       primaryDark: Color(0xFF4ADE80),
//       isPremium: true,
//     ),
//     AppThemeData(
//       id: 'sunset',
//       name: 'Sunset',
//       emoji: '🌅',
//       primaryLight: Color(0xFFEA580C),
//       primaryDark: Color(0xFFFB923C),
//       isPremium: true,
//     ),
//     AppThemeData(
//       id: 'lavender',
//       name: 'Lavender',
//       emoji: '💜',
//       primaryLight: Color(0xFF7C3AED),
//       primaryDark: Color(0xFFA78BFA),
//       isPremium: true,
//     ),
//     AppThemeData(
//       id: 'rose',
//       name: 'Rose',
//       emoji: '🌹',
//       primaryLight: Color(0xFFBE123C),
//       primaryDark: Color(0xFFFB7185),
//       isPremium: true,
//     ),
//     AppThemeData(
//       id: 'galaxy',
//       name: 'Galaxy',
//       emoji: '🌌',
//       primaryLight: Color(0xFF6D28D9),
//       primaryDark: Color(0xFFC4B5FD),
//       isPremiumPlus: true,
//       playfulBackground: true,
//     ),
//     AppThemeData(
//       id: 'neon',
//       name: 'Neon',
//       emoji: '⚡',
//       primaryLight: Color(0xFF0891B2),
//       primaryDark: Color(0xFF22D3EE),
//       isPremiumPlus: true,
//       playfulBackground: true,
//     ),
//     AppThemeData(
//       id: 'gold',
//       name: 'Gold',
//       emoji: '✨',
//       primaryLight: Color(0xFFB45309),
//       primaryDark: Color(0xFFFBBF24),
//       isPremiumPlus: true,
//       playfulBackground: true,
//     ),
//     AppThemeData(
//       id: 'cyber',
//       name: 'Cyber',
//       emoji: '🤖',
//       primaryLight: Color(0xFF047857),
//       primaryDark: Color(0xFF34D399),
//       isPremiumPlus: true,
//       playfulBackground: true,
//     ),
//     AppThemeData(
//       id: 'lava',
//       name: 'Lava',
//       emoji: '🌋',
//       primaryLight: Color(0xFFB91C1C),
//       primaryDark: Color(0xFFF87171),
//       isPremiumPlus: true,
//       playfulBackground: true,
//     ),
//     AppThemeData(
//       id: 'aurora',
//       name: 'Aurora',
//       emoji: '🌈',
//       primaryLight: Color(0xFF0F766E),
//       primaryDark: Color(0xFF2DD4BF),
//       isPremiumPlus: true,
//       playfulBackground: true,
//     ),
//     AppThemeData(
//       id: 'bubblegum',
//       name: 'Bubblegum',
//       emoji: '🫧',
//       primaryLight: Color(0xFFDB2777),
//       primaryDark: Color(0xFFF9A8D4),
//       isPremiumPlus: true,
//       playfulBackground: true,
//     ),
//     AppThemeData(
//       id: 'candy_pop',
//       name: 'Candy Pop',
//       emoji: '🍭',
//       primaryLight: Color(0xFF7C3AED),
//       primaryDark: Color(0xFFDDD6FE),
//       isPremiumPlus: true,
//       playfulBackground: true,
//     ),
//     AppThemeData(
//       id: 'space',
//       name: 'Deep Space',
//       emoji: '🚀',
//       primaryLight: Color(0xFF1D4ED8),
//       primaryDark: Color(0xFF93C5FD),
//       isPremiumPlus: true,
//       playfulBackground: true,
//     ),
//   ];

//   AppThemeData get current => allThemes.firstWhere(
//     (t) => t.id == _currentId,
//     orElse: () => allThemes.first,
//   );

//   ThemeData get lightTheme => current.buildTheme(Brightness.light);
//   ThemeData get darkTheme => current.buildTheme(Brightness.dark);

//   Future<void> load() async {
//     final prefs = await SharedPreferences.getInstance();
//     _currentId = prefs.getString(_prefKey) ?? 'jma3a';
//     final modeStr = prefs.getString(_darkKey) ?? 'system';
//     _themeMode = switch (modeStr) {
//       'light' => ThemeMode.light,
//       'dark' => ThemeMode.dark,
//       _ => ThemeMode.system,
//     };
//     notifyListeners();
//   }

//   Future<void> setThemeMode(ThemeMode mode) async {
//     _themeMode = mode;
//     final prefs = await SharedPreferences.getInstance();
//     final str = switch (mode) {
//       ThemeMode.light => 'light',
//       ThemeMode.dark => 'dark',
//       ThemeMode.system => 'system',
//     };
//     await prefs.setString(_darkKey, str);
//     notifyListeners();
//   }

//   Future<void> toggleDark() async {
//     final next = _themeMode == ThemeMode.dark
//         ? ThemeMode.light
//         : ThemeMode.dark;
//     await setThemeMode(next);
//   }

//   Future<void> setTheme(
//     String id, {
//     required bool isPremiumActive,
//     required bool isPremiumPlus,
//   }) async {
//     final t = allThemes.firstWhere(
//       (t) => t.id == id,
//       orElse: () => allThemes.first,
//     );
//     if (t.isPremiumPlus && !isPremiumPlus) return;
//     if (t.isPremium && !isPremiumActive) return;
//     _currentId = id;
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_prefKey, id);
//     notifyListeners();
//   }

//   List<AppThemeData> availableFor({
//     required bool isPremium,
//     required bool isPremiumPlus,
//   }) => allThemes.where((t) {
//     if (t.isPremiumPlus) return isPremiumPlus;
//     if (t.isPremium) return isPremium;
//     return true;
//   }).toList();
// }

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../extensions/context_ext.dart';
import '../theme/app_theme.dart';

enum BackgroundMotif {
  none,
  bubbles,
  stars,
  sparkles,
  flames,
  leaves,
  confetti,
  hearts,
  rockets,
}

class AppThemeData {
  const AppThemeData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.primaryLight,
    required this.primaryDark,
    this.isPremium = false,
    this.isPremiumPlus = false,
    this.motif = BackgroundMotif.none,
  });

  /// [name] is a stable, English, NEVER-shown-directly identifier — kept
  /// only because [id] alone wasn't always distinct from a human-readable
  /// label historically and other code may still read it for logging/
  /// debugging. Every UI surface MUST call [appThemeLocalizedName] instead
  /// of reading this field for display — see that function's own doc
  /// comment for why (item 5's localization audit found this was
  /// previously shown to the user as hardcoded English with no
  /// translation at all).
  final String id, name, emoji;
  final Color primaryLight;
  final Color primaryDark;
  final bool isPremium;
  final bool isPremiumPlus;
  final BackgroundMotif motif;

  ThemeData buildTheme(Brightness brightness, {Color? backgroundOverride}) =>
      AppTheme.withPrimary(
        brightness == Brightness.light ? primaryLight : primaryDark,
        brightness,
        backgroundOverride: backgroundOverride,
      );
}

/// Item 5 fix — resolves an [AppThemeData.id] to its localized display
/// name. [AppThemeService.allThemes] is a top-level `const` list (cheap to
/// define/extend as a single compile-time constant), so it cannot hold a
/// `context.l10n`-resolved string directly — every theme name used to be
/// shown to the user as hardcoded English with no translation at all.
/// A switch (not a Map) so an unrecognized id is a compile-time-obvious
/// dead branch rather than a silent lookup miss — falls back to
/// [AppThemeData.name] itself only as a last resort, which should never
/// actually happen since every id in [AppThemeService.allThemes] has a
/// case here.
String appThemeLocalizedName(BuildContext context, AppThemeData theme) {
  final l10n = context.l10n;
  return switch (theme.id) {
    'jma3a' => l10n.appThemeNameJma3a,
    'midnight' => l10n.appThemeNameMidnight,
    'slate' => l10n.appThemeNameClassic,
    'candy' => l10n.appThemeNameCandy,
    'ocean' => l10n.appThemeNameOcean,
    'forest' => l10n.appThemeNameForest,
    'sunset' => l10n.appThemeNameSunset,
    'lavender' => l10n.appThemeNameLavender,
    'rose' => l10n.appThemeNameRose,
    'galaxy' => l10n.appThemeNameGalaxy,
    'neon' => l10n.appThemeNameNeon,
    'gold' => l10n.appThemeNameGold,
    'cyber' => l10n.appThemeNameCyber,
    'lava' => l10n.appThemeNameLava,
    'aurora' => l10n.appThemeNameAurora,
    'bubblegum' => l10n.appThemeNameBubblegum,
    'candy_pop' => l10n.appThemeNameCandyPop,
    'space' => l10n.appThemeNameDeepSpace,
    'blossom' => l10n.appThemeNameBlossom,
    'lovestruck' => l10n.appThemeNameLovestruck,
    _ => theme.name,
  };
}

/// Items 5-8 (this pass) — a single, front-card-only color for
/// GameFlipCard's shell, independent of the user's Background Color
/// (profiles.theme_background_color) and independent of [AppThemeData]
/// (the app-wide primary-color theme). See GameFlipCard's own doc comment
/// for exactly how [gradientColors]/[borderGlowColor] are applied to ONLY
/// the front face — the back face always keeps GameFlipCard's existing
/// default shell color, never this override.
///
/// [gradientColors] is a 3-stop radial-gradient palette (brightest ->
/// darkest) matching the EXACT structure GameFlipCard's shared shell
/// already uses for its one hardcoded purple gradient — swapping only the
/// hue/tone, not the visual language (radial glow, dark base) the rest of
/// the card's decorations/white text/logo were designed against. Every
/// entry is deliberately kept dark/saturated enough to preserve contrast
/// with the card's white text, icons, and logo (see this class's own
/// curation note in AppThemeService.gameCardColors) — none of these are
/// exposed to the user as a raw color picker.
class GameCardColorData {
  const GameCardColorData({
    required this.id,
    required this.gradientColors,
    required this.borderGlowColor,
  });

  final String id;

  /// Exactly 3 colors: [center-brightest, mid, edge-darkest] — passed
  /// straight into the same RadialGradient shape GameFlipCard's shell
  /// already builds.
  final List<Color> gradientColors;

  /// Border + glow tint (replaces the shell's hardcoded neonPink for the
  /// front face only) — chosen per palette entry so the accent color
  /// still reads as intentional against that entry's own gradient, rather
  /// of one fixed pink clashing with every hue.
  final Color borderGlowColor;
}

/// Item 5 fix — resolves a [GameCardColorData.id] to its localized display
/// name. Mirrors [appThemeLocalizedName]'s exact pattern/reasoning (a
/// switch, not a Map, over a top-level `const` palette that can't hold a
/// context.l10n-resolved string directly) — see that function's own doc
/// comment.
String gameCardColorLocalizedName(BuildContext context, String id) {
  final l10n = context.l10n;
  return switch (id) {
    'classic_purple' => l10n.gameCardColorClassicPurple,
    'midnight_blue' => l10n.gameCardColorMidnightBlue,
    'ember_red' => l10n.gameCardColorEmberRed,
    'forest_emerald' => l10n.gameCardColorForestEmerald,
    'sunset_orange' => l10n.gameCardColorSunsetOrange,
    'gold_prestige' => l10n.gameCardColorGoldPrestige,
    'rose_pink' => l10n.gameCardColorRosePink,
    'cyber_teal' => l10n.gameCardColorCyberTeal,
    _ => id,
  };
}

class AppThemeService extends ChangeNotifier {
  AppThemeService._();
  static final AppThemeService instance = AppThemeService._();

  static const _prefKey = 'app_theme_id_v2';
  static const _darkKey = 'app_theme_dark_v2';

  /// Item 10 — LOCAL persistence only (SharedPreferences), mirroring
  /// [_prefKey]/[_darkKey]'s existing pattern exactly, deliberately NOT
  /// the server-synced pattern Background Color uses (profiles.
  /// theme_background_color via the set_theme_background_color RPC —
  /// see ProfileRepository.setThemeBackgroundColor). That would need a
  /// new DB column + RPC, which this task's own constraints forbid
  /// (no migrations, no Supabase access); Game Card Color is also not a
  /// Premium-gated setting like Background Color is, so the app-theme-id/
  /// dark-mode local-only pattern is the correct existing architecture to
  /// follow here, not the background-color one.
  static const _gameCardColorPrefKey = 'app_game_card_color_v1';

  String _currentId = 'jma3a';
  ThemeMode _themeMode = ThemeMode.system;
  String _gameCardColorId = defaultGameCardColorId;

  String get currentId => _currentId;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  String get gameCardColorId => _gameCardColorId;

  static const List<AppThemeData> allThemes = [
    AppThemeData(
      id: 'jma3a',
      name: 'Jma3a',
      emoji: '🎮',
      primaryLight: Color(0xFF1D4ED8),
      primaryDark: Color(0xFF60A5FA),
    ),
    AppThemeData(
      id: 'midnight',
      name: 'Midnight',
      emoji: '🌙',
      primaryLight: Color(0xFF1E40AF),
      primaryDark: Color(0xFF93C5FD),
    ),
    AppThemeData(
      id: 'slate',
      name: 'Classic',
      emoji: '🎨',
      primaryLight: Color(0xFF334155),
      primaryDark: Color(0xFF94A3B8),
    ),
    AppThemeData(
      id: 'candy',
      name: 'Candy',
      emoji: '🍬',
      primaryLight: Color(0xFFBE185D),
      primaryDark: Color(0xFFF472B6),
      isPremium: true,
    ),
    AppThemeData(
      id: 'ocean',
      name: 'Ocean',
      emoji: '🌊',
      primaryLight: Color(0xFF0369A1),
      primaryDark: Color(0xFF38BDF8),
      isPremium: true,
    ),
    AppThemeData(
      id: 'forest',
      name: 'Forest',
      emoji: '🌲',
      primaryLight: Color(0xFF166534),
      primaryDark: Color(0xFF4ADE80),
      isPremium: true,
    ),
    AppThemeData(
      id: 'sunset',
      name: 'Sunset',
      emoji: '🌅',
      primaryLight: Color(0xFFEA580C),
      primaryDark: Color(0xFFFB923C),
      isPremium: true,
    ),
    AppThemeData(
      id: 'lavender',
      name: 'Lavender',
      emoji: '💜',
      primaryLight: Color(0xFF7C3AED),
      primaryDark: Color(0xFFA78BFA),
      isPremium: true,
    ),
    AppThemeData(
      id: 'rose',
      name: 'Rose',
      emoji: '🌹',
      primaryLight: Color(0xFFBE123C),
      primaryDark: Color(0xFFFB7185),
      isPremium: true,
    ),
    AppThemeData(
      id: 'galaxy',
      name: 'Galaxy',
      emoji: '🌌',
      primaryLight: Color(0xFF6D28D9),
      primaryDark: Color(0xFFC4B5FD),
      isPremiumPlus: true,
      motif: BackgroundMotif.stars,
    ),
    AppThemeData(
      id: 'neon',
      name: 'Neon',
      emoji: '⚡',
      primaryLight: Color(0xFF0891B2),
      primaryDark: Color(0xFF22D3EE),
      isPremiumPlus: true,
      motif: BackgroundMotif.sparkles,
    ),
    AppThemeData(
      id: 'gold',
      name: 'Gold',
      emoji: '✨',
      primaryLight: Color(0xFFB45309),
      primaryDark: Color(0xFFFBBF24),
      isPremiumPlus: true,
      motif: BackgroundMotif.sparkles,
    ),
    AppThemeData(
      id: 'cyber',
      name: 'Cyber',
      emoji: '🤖',
      primaryLight: Color(0xFF047857),
      primaryDark: Color(0xFF34D399),
      isPremiumPlus: true,
      motif: BackgroundMotif.sparkles,
    ),
    AppThemeData(
      id: 'lava',
      name: 'Lava',
      emoji: '🌋',
      primaryLight: Color(0xFFB91C1C),
      primaryDark: Color(0xFFF87171),
      isPremiumPlus: true,
      motif: BackgroundMotif.flames,
    ),
    AppThemeData(
      id: 'aurora',
      name: 'Aurora',
      emoji: '🌈',
      primaryLight: Color(0xFF0F766E),
      primaryDark: Color(0xFF2DD4BF),
      isPremiumPlus: true,
      motif: BackgroundMotif.stars,
    ),
    AppThemeData(
      id: 'bubblegum',
      name: 'Bubblegum',
      emoji: '🫧',
      primaryLight: Color(0xFFDB2777),
      primaryDark: Color(0xFFF9A8D4),
      isPremiumPlus: true,
      motif: BackgroundMotif.bubbles,
    ),
    AppThemeData(
      id: 'candy_pop',
      name: 'Candy Pop',
      emoji: '🍭',
      primaryLight: Color(0xFF7C3AED),
      primaryDark: Color(0xFFDDD6FE),
      isPremiumPlus: true,
      motif: BackgroundMotif.confetti,
    ),
    AppThemeData(
      id: 'space',
      name: 'Deep Space',
      emoji: '🚀',
      primaryLight: Color(0xFF1D4ED8),
      primaryDark: Color(0xFF93C5FD),
      isPremiumPlus: true,
      motif: BackgroundMotif.rockets,
    ),
    AppThemeData(
      id: 'blossom',
      name: 'Blossom',
      emoji: '🌸',
      primaryLight: Color(0xFFDB2777),
      primaryDark: Color(0xFFF472B6),
      isPremiumPlus: true,
      motif: BackgroundMotif.leaves,
    ),
    AppThemeData(
      id: 'lovestruck',
      name: 'Lovestruck',
      emoji: '💕',
      primaryLight: Color(0xFFE11D48),
      primaryDark: Color(0xFFFB7185),
      isPremiumPlus: true,
      motif: BackgroundMotif.hearts,
    ),
  ];

  /// Items 5/6 — the curated Game Card Color palette. 'classic_purple' is
  /// first and is [defaultGameCardColorId]: the EXACT gradient/border
  /// GameFlipCard's shell already hardcoded before this feature existed
  /// (see GameFlipCard's own front-shell color), so a user who has never
  /// opened this setting sees zero visual change. Every other entry is a
  /// different hue at a comparably dark/saturated tone — "dark, warm,
  /// cool, playful, premium-looking" per the product ask — deliberately
  /// NOT including a literal light/pastel option: the front card's actual
  /// game-prompt TEXT (each game screen's own frontChild/
  /// frontContentBuilder content) is drawn in colors this shared palette
  /// does not and cannot control, and those are designed for a dark card
  /// background. A pastel option here would risk exactly the unreadable-
  /// text problem this task explicitly warns against, for content this
  /// component has no authority to also recolor.
  static const String defaultGameCardColorId = 'classic_purple';

  static const List<GameCardColorData> gameCardColors = [
    GameCardColorData(
      id: 'classic_purple',
      gradientColors: [Color(0xFF4C2E8C), Color(0xFF2A1854), Color(0xFF130A29)],
      borderGlowColor: Color(0xFFFF3D9A), // AppColors.neonPink
    ),
    GameCardColorData(
      id: 'midnight_blue',
      gradientColors: [Color(0xFF1E3A8A), Color(0xFF1B2450), Color(0xFF0A0F26)],
      borderGlowColor: Color(0xFF38DFF0),
    ),
    GameCardColorData(
      id: 'ember_red',
      gradientColors: [Color(0xFF9A2E2E), Color(0xFF551818), Color(0xFF260A0A)],
      borderGlowColor: Color(0xFFFFA23D),
    ),
    GameCardColorData(
      id: 'forest_emerald',
      gradientColors: [Color(0xFF1F6B4A), Color(0xFF143F2C), Color(0xFF091E15)],
      borderGlowColor: Color(0xFF5CF2B0),
    ),
    GameCardColorData(
      id: 'sunset_orange',
      gradientColors: [Color(0xFFB85A1E), Color(0xFF7A3512), Color(0xFF2E1408)],
      borderGlowColor: Color(0xFFFFD24C),
    ),
    GameCardColorData(
      id: 'gold_prestige',
      gradientColors: [Color(0xFF4A3A16), Color(0xFF241C0A), Color(0xFF120E05)],
      borderGlowColor: Color(0xFFE8C25E),
    ),
    GameCardColorData(
      id: 'rose_pink',
      gradientColors: [Color(0xFF9A2E68), Color(0xFF551838), Color(0xFF260A19)],
      borderGlowColor: Color(0xFFFF6FB8),
    ),
    GameCardColorData(
      id: 'cyber_teal',
      gradientColors: [Color(0xFF0E5C5C), Color(0xFF0A3838), Color(0xFF041818)],
      borderGlowColor: Color(0xFF4CF0E0),
    ),
  ];

  GameCardColorData get currentGameCardColor => gameCardColors.firstWhere(
    (c) => c.id == _gameCardColorId,
    orElse: () => gameCardColors.first,
  );

  AppThemeData get current => allThemes.firstWhere(
    (t) => t.id == _currentId,
    orElse: () => allThemes.first,
  );

  ThemeData lightTheme({Color? backgroundOverride}) => current.buildTheme(
    Brightness.light,
    backgroundOverride: backgroundOverride,
  );
  ThemeData darkTheme({Color? backgroundOverride}) => current.buildTheme(
    Brightness.dark,
    backgroundOverride: backgroundOverride,
  );

  // Ephemeral, in-memory-only preview color for the background-color
  // picker sheet — never persisted. Takes priority over the persisted
  // value (see _RouterHostState.build() in app.dart) while a picker is
  // open, so the whole app re-themes live before the user commits, without
  // touching the actual saved preference until Save is pressed.
  Color? _previewBackgroundColor;
  Color? get previewBackgroundColor => _previewBackgroundColor;

  void previewBackground(Color? color) {
    _previewBackgroundColor = color;
    notifyListeners();
  }

  void clearPreviewBackground() {
    if (_previewBackgroundColor == null) return;
    _previewBackgroundColor = null;
    notifyListeners();
  }

  /// Parses a "#RRGGBB" hex string (the format stored in
  /// profiles.theme_background_color) into a [Color], or null if absent/
  /// malformed.
  static Color? parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final s = hex.startsWith('#') ? hex.substring(1) : hex;
    if (s.length != 6) return null;
    final v = int.tryParse(s, radix: 16);
    return v == null ? null : Color(0xFF000000 | v);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _currentId = prefs.getString(_prefKey) ?? 'jma3a';
    final modeStr = prefs.getString(_darkKey) ?? 'system';
    _themeMode = switch (modeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _gameCardColorId =
        prefs.getString(_gameCardColorPrefKey) ?? defaultGameCardColorId;
    notifyListeners();
  }

  /// Items 6/10 — persists the chosen Game Card Color locally (see
  /// [_gameCardColorPrefKey]'s own doc comment for why local, not the
  /// server-synced pattern Background Color uses). An unrecognized id is
  /// never persisted or applied — [currentGameCardColor] already falls
  /// back safely, but this keeps the stored preference itself always
  /// valid too.
  Future<void> setGameCardColor(String id) async {
    if (!gameCardColors.any((c) => c.id == id)) return;
    _gameCardColorId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gameCardColorPrefKey, id);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    final str = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_darkKey, str);
    notifyListeners();
  }

  Future<void> toggleDark() async {
    final next = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(next);
  }

  Future<void> setTheme(
    String id, {
    required bool isPremiumActive,
    required bool isPremiumPlus,
  }) async {
    final t = allThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => allThemes.first,
    );
    if (t.isPremiumPlus && !isPremiumPlus) return;
    if (t.isPremium && !isPremiumActive) return;
    _currentId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, id);
    notifyListeners();
  }

  List<AppThemeData> availableFor({
    required bool isPremium,
    required bool isPremiumPlus,
  }) => allThemes.where((t) {
    if (t.isPremiumPlus) return isPremiumPlus;
    if (t.isPremium) return isPremium;
    return true;
  }).toList();
}
