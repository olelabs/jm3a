// Regression coverage for the mute-icon correction: MemberTile's mute
// indicator/action previously used microphone icons (Icons.mic_off_rounded
// / Icons.mic_rounded / Icons.mic_off_outlined), which wrongly implied a
// voice-chat feature. RoomMemberEntity.isMuted is documented as a TEXT
// CHAT mute only (see its own doc comment: "only silences text chat —
// do not conflate [with isGameMuted]"), never voice/audio — this app has
// no live voice-chat feature at all. The fix swaps to
// notifications_off/notifications_active icons, which communicate
// "muted" without suggesting a microphone/voice/game-audio feature.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:jma3a/features/rooms/presentation/widgets/member_tile.dart';

RoomMemberEntity _member({bool isMuted = false}) => RoomMemberEntity(
  userId: 'u1',
  displayName: 'Sara',
  seatOrder: 0,
  isReady: false,
  isOwner: false,
  isModerator: false,
  isMuted: isMuted,
);

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  group('MemberTile — muted-member avatar badge', () {
    testWidgets('shows notifications_off, never a microphone icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          MemberTile(
            member: _member(isMuted: true),
            isCurrentUser: false,
            canModerate: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.notifications_off_rounded), findsOneWidget);
      expect(find.byIcon(Icons.mic_off_rounded), findsNothing);
      expect(find.byIcon(Icons.mic_rounded), findsNothing);
      expect(find.byIcon(Icons.mic_off_outlined), findsNothing);
    });

    testWidgets('no mute badge at all for an unmuted member', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MemberTile(
            member: _member(isMuted: false),
            isCurrentUser: false,
            canModerate: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.notifications_off_rounded), findsNothing);
    });
  });

  group('MemberTile — moderation menu mute action', () {
    testWidgets(
      'unmuted member: menu offers "Mute player" with a notifications_off '
      'icon, never a microphone icon',
      (tester) async {
        var muteTaps = 0;
        await tester.pumpWidget(
          _wrap(
            MemberTile(
              member: _member(isMuted: false),
              isCurrentUser: false,
              canModerate: true,
              onMute: () => muteTaps++,
            ),
          ),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.more_vert_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Mute player'), findsOneWidget);
        expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
        expect(find.byIcon(Icons.mic_off_outlined), findsNothing);
        expect(find.byIcon(Icons.mic_rounded), findsNothing);

        await tester.tap(find.text('Mute player'));
        await tester.pumpAndSettle();
        expect(muteTaps, 1);
      },
    );

    testWidgets(
      'muted member: menu offers "Unmute" with a notifications_active '
      'icon, never a microphone icon',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            MemberTile(
              member: _member(isMuted: true),
              isCurrentUser: false,
              canModerate: true,
              onMute: () {},
            ),
          ),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.more_vert_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Unmute'), findsOneWidget);
        expect(
          find.byIcon(Icons.notifications_active_outlined),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.mic_rounded), findsNothing);
        expect(find.byIcon(Icons.mic_off_outlined), findsNothing);
      },
    );
  });
}
