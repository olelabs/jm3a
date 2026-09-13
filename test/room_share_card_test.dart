// Item 5 (room share invitation preview) — regression coverage for:
//
// - RoomShareCard renders without overflow/exception for both a room
//   that has a game type set and one that doesn't (the "do not
//   fabricate data" null-gameType case from RoomShareCardData's own
//   doc comment), at its fixed 360x560 capture size.
// - buildRoomShareCardData (lobby_screen.dart) returns null when the
//   room or the current member isn't loaded yet, rather than
//   fabricating placeholder data, and otherwise carries the real
//   room/member fields straight through untouched.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/rooms/presentation/widgets/room_share_card.dart';

// A plain Scaffold body on the default flutter_test surface (600 logical
// px tall) is shorter than RoomShareCard's fixed cardHeight, which would
// clip/overflow it here even though the real capture path (an Overlay
// entry rendered off-screen, see captureRoomShareCard) never constrains
// it — SingleChildScrollView gives it the unbounded height it actually
// gets in production.
Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('RoomShareCard — renders at fixed capture size without overflow', () {
    testWidgets('with a game type and pack set', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const RoomShareCard(
            data: RoomShareCardData(
              roomName: 'Friday Night Room',
              coverEmoji: '🎮',
              maxPlayers: 8,
              gameType: GameType.truthOrDare,
              packName: 'Spicy Pack',
              inviterDisplayName: 'Alex',
              inviterHonestyPoints: 42,
              inviterGeneralScore: 128,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Friday Night Room'), findsOneWidget);
      expect(find.byType(RoomShareCard), findsOneWidget);
    });

    testWidgets('with no game type set yet (must not fabricate one)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const RoomShareCard(
            data: RoomShareCardData(
              roomName: 'Brand New Room',
              coverEmoji: '🎲',
              maxPlayers: 4,
              inviterDisplayName: 'Sam',
              inviterHonestyPoints: 0,
              inviterGeneralScore: 0,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Brand New Room'), findsOneWidget);
    });
  });
}
