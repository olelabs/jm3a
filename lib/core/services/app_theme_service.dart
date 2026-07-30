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

class AppThemeService extends ChangeNotifier {
  AppThemeService._();
  static final AppThemeService instance = AppThemeService._();

  static const _prefKey = 'app_theme_id_v2';
  static const _darkKey = 'app_theme_dark_v2';

  String _currentId = 'jma3a';
  ThemeMode _themeMode = ThemeMode.system;

  String get currentId => _currentId;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

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

  AppThemeData get current => allThemes.firstWhere(
    (t) => t.id == _currentId,
    orElse: () => allThemes.first,
  );

  ThemeData lightTheme({Color? backgroundOverride}) =>
      current.buildTheme(Brightness.light, backgroundOverride: backgroundOverride);
  ThemeData darkTheme({Color? backgroundOverride}) =>
      current.buildTheme(Brightness.dark, backgroundOverride: backgroundOverride);

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
