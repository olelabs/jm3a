// Phase 4A (packs localization) — regression coverage for the Packs
// marketplace game-type filter chips, which previously rendered
// hardcoded English labels (GameType.displayName) instead of the
// already-existing, already-fully-translated context.l10n.gameName*
// keys used identically everywhere else in the app (room_share_card.dart,
// room_browser_screen.dart, game_settings_sheet.dart, ...). Tests the
// extracted pure function directly (gameTypeFilterLabel, in
// marketplace_screen.dart) per locale — no widget pump needed, matching
// intro_screen_rapid_navigation_test.dart's AppLocalizations.delegate.
// load precedent for locale-parametrized pure-function tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/packs/presentation/screens/marketplace_screen.dart';

Future<AppLocalizations> _load(String code) =>
    AppLocalizations.delegate.load(Locale(code));

void main() {
  group('gameTypeFilterLabel', () {
    test('English', () async {
      final l10n = await _load('en');
      expect(
        gameTypeFilterLabel(l10n, GameType.truthOrDare),
        'Truth or Dare',
      );
      expect(
        gameTypeFilterLabel(l10n, GameType.neverHaveIEver),
        'Never Have I',
      );
      expect(gameTypeFilterLabel(l10n, GameType.memeGame), 'Meme Game');
    });

    test('French', () async {
      final l10n = await _load('fr');
      expect(
        gameTypeFilterLabel(l10n, GameType.truthOrDare),
        'Action ou Vérité',
      );
      expect(
        gameTypeFilterLabel(l10n, GameType.neverHaveIEver),
        'Je n\'ai jamais',
      );
      expect(gameTypeFilterLabel(l10n, GameType.memeGame), 'Jeu de Mèmes');
    });

    test('Arabic', () async {
      final l10n = await _load('ar');
      expect(
        gameTypeFilterLabel(l10n, GameType.truthOrDare),
        'الحقيقة أم الجرأة',
      );
      expect(
        gameTypeFilterLabel(l10n, GameType.neverHaveIEver),
        'لم أفعل من قبل',
      );
      expect(gameTypeFilterLabel(l10n, GameType.memeGame), 'لعبة الميم');
    });

    test(
      'never falls back to GameType.displayName\'s hardcoded English for '
      'a non-English locale',
      () async {
        final ar = await _load('ar');
        expect(
          gameTypeFilterLabel(ar, GameType.truthOrDare),
          isNot(GameType.truthOrDare.displayName),
        );
      },
    );
  });
}
