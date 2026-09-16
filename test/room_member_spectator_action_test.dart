// Item 4 (remove "switch player to spectator" from the active game) —
// investigation found the action lived ONLY in RoomMembersManagementSheet
// (opened exclusively from the three active-game screens via
// RoomMembersFab: tod/nhie/meme_game_screen.dart) — the room lobby's own
// member list (MemberTile) never exposed a spectator-toggle action at
// all, contrary to the "currently shared between lobby and active game"
// assumption. This file pins that lobby baseline (MemberTile's
// moderation menu has never offered — and must continue to never offer —
// a spectator action) so a future change can't accidentally reintroduce
// it there instead of through a deliberate, separate lobby-specific
// control.
//
// RoomMembersManagementSheet itself requires a live, heavily
// Supabase-backed RoomProvider to construct (no existing test in this
// repo pumps it directly, for the same reason) — the active-game removal
// (canSetSpectator's dead local variable and the "Set/Remove Spectator"
// TextButton block deleted entirely, _toggleSpectator's now-dead wrapper
// removed) is verified by direct code review instead, consistent with
// this codebase's established boundary for Provider/Supabase-singleton-
// backed widgets.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:jma3a/features/rooms/presentation/widgets/member_tile.dart';

RoomMemberEntity _member() => const RoomMemberEntity(
  userId: 'u1',
  displayName: 'Sara',
  seatOrder: 0,
  isReady: false,
  isOwner: false,
  isModerator: false,
);

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets(
    'the room lobby member tile (MemberTile) never offers a '
    'switch-to-spectator action — no such callback exists on the widget '
    'at all',
    (tester) async {
      var kickTaps = 0;
      var muteTaps = 0;
      await tester.pumpWidget(
        _wrap(
          MemberTile(
            member: _member(),
            isCurrentUser: false,
            canModerate: true,
            onKick: () => kickTaps++,
            onMute: () => muteTaps++,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      // The menu offers exactly what MemberTile's own constructor
      // callbacks describe (Mute, Kick here) — no "spectator" wording of
      // any kind, in a widget that structurally has no onSpectator-style
      // parameter to even wire one through.
      expect(find.textContaining('pectator'), findsNothing);
      expect(kickTaps, 0);
      expect(muteTaps, 0);
    },
  );
}
