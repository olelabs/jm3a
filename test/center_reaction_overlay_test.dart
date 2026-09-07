// Widget tests for the shared CenterReactionOverlay used by every game:
// a new reaction is shown ONCE, centered, with the reactor's name, and is
// dismissed by a tap or after the display duration. Uses an emoji reaction so
// no avatar assets/network are involved.

import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:jma3a/shared/widgets/animated_reaction_overlay.dart'
    show ReactionEvent;
import 'package:jma3a/shared/widgets/center_reaction_overlay.dart';

RoomMemberEntity _member(String id) => RoomMemberEntity(
      userId: id,
      displayName: 'name-$id',
      seatOrder: 0,
      isReady: false,
      isOwner: false,
      isModerator: false,
    );

Future<void> _pumpOverlay(
  WidgetTester tester,
  ValueNotifier<List<ReactionEvent>> reactions,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            const SizedBox.expand(),
            ValueListenableBuilder<List<ReactionEvent>>(
              valueListenable: reactions,
              builder: (_, list, _) => CenterReactionOverlay(
                reactions: list,
                avatarResolver: _member,
                displayDuration: const Duration(seconds: 3),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a new reaction appears centered with the reactor name', (
    tester,
  ) async {
    // '🥳' is NOT in kAnimatedEmojiMap, so it renders as a plain Text glyph
    // (mapped emojis now render as AnimatedEmoji — covered separately).
    final reactions = ValueNotifier<List<ReactionEvent>>([]);
    await _pumpOverlay(tester, reactions);
    expect(find.text('🥳'), findsNothing);

    reactions.value = [(emoji: '🥳', ts: 1, userId: 'u1')];
    await tester.pump(); // didUpdateWidget enqueues + shows
    await tester.pump(const Duration(milliseconds: 300)); // scale-in tween

    expect(find.text('🥳'), findsOneWidget);
    expect(find.text('name-u1'), findsOneWidget);

    // Dismiss with a tap anywhere.
    await tester.tap(find.byType(CenterReactionOverlay));
    await tester.pump();
    expect(find.text('🥳'), findsNothing);
  });

  testWidgets('auto-dismisses after the display duration', (tester) async {
    final reactions = ValueNotifier<List<ReactionEvent>>([]);
    await _pumpOverlay(tester, reactions);

    reactions.value = [(emoji: '🎈', ts: 2, userId: 'u2')]; // unmapped → Text
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('🎈'), findsOneWidget);

    // After 3s it clears itself.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('🎈'), findsNothing);
  });

  testWidgets('a reaction already present at mount does NOT replay', (
    tester,
  ) async {
    // Seeded in initState — reconnecting mid-round must not pop old reactions.
    final reactions = ValueNotifier<List<ReactionEvent>>([
      (emoji: '💯', ts: 3, userId: 'u3'),
    ]);
    await _pumpOverlay(tester, reactions);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('💯'), findsNothing);
  });

  // Issue 2: icon reactions must ANIMATE again — a mapped emoji renders an
  // AnimatedEmoji (Lottie), not a static glyph.
  testWidgets('a mapped emoji reaction renders an animated emoji', (
    tester,
  ) async {
    final reactions = ValueNotifier<List<ReactionEvent>>([]);
    await _pumpOverlay(tester, reactions);
    reactions.value = [(emoji: '😂', ts: 1, userId: 'u1')];
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AnimatedEmoji), findsOneWidget);
  });

  // Issue 4: an avatar reaction must resolve the avatar by the REACTOR's
  // userId, never the current viewer.
  testWidgets('an avatar reaction resolves the reactor, not the viewer', (
    tester,
  ) async {
    final resolvedUserIds = <String>[];
    final reactions = ValueNotifier<List<ReactionEvent>>([]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const SizedBox.expand(),
              ValueListenableBuilder<List<ReactionEvent>>(
                valueListenable: reactions,
                builder: (_, list, _) => CenterReactionOverlay(
                  reactions: list,
                  avatarResolver: (id) {
                    resolvedUserIds.add(id);
                    return _member(id);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // An avatar-style reaction (value "avatar:<key>") from a specific reactor.
    reactions.value = [(emoji: 'avatar:laugh', ts: 9, userId: 'reactorX')];
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // UserAvatar can't fully render a real avatar without assets in a unit
    // test — consume that expected render error. What matters here is that the
    // overlay resolved the REACTOR's userId (never the viewer's) BEFORE
    // building the avatar.
    tester.takeException();
    expect(resolvedUserIds, contains('reactorX'));
    expect(resolvedUserIds, isNot(contains('viewer')));
  });
}
