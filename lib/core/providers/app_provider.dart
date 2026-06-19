import 'package:flutter/material.dart';
import 'package:jma3a/core/storage/local_storage_service.dart';

// import '../services/local_storage_service.dart';

/// App-wide UI state: theme, locale, and global loading state.
///
/// Lives at the root MultiProvider. Never disposed.
class AppProvider extends ChangeNotifier {
  AppProvider({required LocalStorageService localStorageService})
    : _storage = localStorageService;

  final LocalStorageService _storage;

  // ── Theme ──────────────────────────────────────────────────────────────
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _storage.setString(_Keys.themeMode, mode.name);
    notifyListeners();
  }

  // ── Locale ─────────────────────────────────────────────────────────────
  static const _supportedLocales = [Locale('en'), Locale('ar'), Locale('fr')];

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  List<Locale> get supportedLocales => _supportedLocales;

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    if (!_supportedLocales.contains(locale)) return;
    _locale = locale;
    await _storage.setString(_Keys.locale, locale.languageCode);
    notifyListeners();
  }

  // ── Initialization ─────────────────────────────────────────────────────
  Future<void> initialize() async {
    // Restore theme
    final savedTheme = _storage.getString(_Keys.themeMode);
    _themeMode = switch (savedTheme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    // Restore locale
    final savedLang = _storage.getString(_Keys.locale);
    if (savedLang != null) {
      final saved = Locale(savedLang);
      if (_supportedLocales.contains(saved)) {
        _locale = saved;
      }
    }

    notifyListeners();
  }
}

abstract final class _Keys {
  static const themeMode = 'app.theme_mode';
  static const locale = 'app.locale';
}
