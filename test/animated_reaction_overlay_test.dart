// Widget tests for AnimatedReactionOverlay — the shared floating-reaction
// presenter used by every game (Truth or Dare, NHIE, Meme): each reaction
// floats from the bottom-right toward the center, fading out, showing its
// own icon/emoji/custom reaction graphic + the reactor's NAME (no profile-
// picture avatar — see _ReactionContent's own doc comment for the one
// exception: an avatar-TOKEN reaction's expressive avatar is the reaction
// graphic itself, not an identity photo, and stays). Each flight has its
// own independent animation lifecycle. Replaces CenterReactionOverlay
// (single-reaction, centered, queued) — see this file's own class doc
// comment for why.

import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/theme/j_theme_extension.dart';
import 'package:jma3a/features/avatar/presentation/avatar_creator_screen.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:jma3a/shared/widgets/animated_reaction_overlay.dart';
import 'package:jma3a/shared/widgets/cards/user_avatar.dart';

// An avatar-token reaction still renders a UserAvatar (the expressive
// avatar IS its reaction graphic) — UserAvatar reads context.jColors
// (Theme.of(context).extension<JThemeExtension>()!), which a bare
// MaterialApp() theme doesn't register. Providing it here is what lets
// that one test render real widget content instead of hitting a
// red-screen null-check failure.
ThemeData _testTheme() => ThemeData(extensions: const [JThemeExtension.light]);

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
  ValueNotifier<List<ReactionEvent>> reactions, {
  AvatarReactionResolver? resolver,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: _testTheme(),
      home: Scaffold(
        body: Stack(
          children: [
            const SizedBox.expand(),
            Positioned.fill(
              child: ValueListenableBuilder<List<ReactionEvent>>(
                valueListenable: reactions,
                builder: (_, list, _) => AnimatedReactionOverlay(
                  reactions: list,
                  avatarResolver: resolver ?? _member,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a single reaction renders its icon and the reactor name', (
    tester,
  ) async {
    final reactions = ValueNotifier<List<ReactionEvent>>([]);
    await _pumpOverlay(tester, reactions);
    expect(find.text('🥳'), findsNothing);

    // '🥳' is NOT in kAnimatedEmojiMap, so it renders as a plain Text glyph.
    reactions.value = [(emoji: '🥳', ts: 1, userId: 'u1')];
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('🥳'), findsOneWidget);
    expect(find.text('name-u1'), findsOneWidget);
  });

  testWidgets(
    'multiple reactions coexist simultaneously — a new one never replaces '
    'an existing one',
    (tester) async {
      final reactions = ValueNotifier<List<ReactionEvent>>([]);
      await _pumpOverlay(tester, reactions);

      reactions.value = [(emoji: '🥳', ts: 1, userId: 'u1')];
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('🥳'), findsOneWidget);

      // A second, different event arrives well before the first has any
      // chance to finish (durations are 3.6s+).
      reactions.value = [
        (emoji: '🥳', ts: 1, userId: 'u1'),
        (emoji: '🎈', ts: 2, userId: 'u2'),
      ];
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Both are present at once — the first was never removed/replaced.
      expect(find.text('🥳'), findsOneWidget);
      expect(find.text('name-u1'), findsOneWidget);
      expect(find.text('🎈'), findsOneWidget);
      expect(find.text('name-u2'), findsOneWidget);
    },
  );

  testWidgets('different users each display their own correct name', (
    tester,
  ) async {
    final reactions = ValueNotifier<List<ReactionEvent>>([]);
    await _pumpOverlay(tester, reactions);

    reactions.value = [
      (emoji: '🔥', ts: 1, userId: 'alice'),
      (emoji: '💀', ts: 2, userId: 'bob'),
    ];
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('name-alice'), findsOneWidget);
    expect(find.text('name-bob'), findsOneWidget);
  });

  testWidgets(
    'repeated reactions from the SAME user each get their own independent '
    'flight, none replacing the other',
    (tester) async {
      final reactions = ValueNotifier<List<ReactionEvent>>([]);
      await _pumpOverlay(tester, reactions);

      reactions.value = [
        (emoji: '🥳', ts: 1, userId: 'u1'),
        (emoji: '🎈', ts: 2, userId: 'u1'),
      ];
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('🥳'), findsOneWidget);
      expect(find.text('🎈'), findsOneWidget);
      expect(find.text('name-u1'), findsNWidgets(2));
    },
  );

  testWidgets(
    'a reaction eventually removes itself once its flight completes',
    (tester) async {
      final reactions = ValueNotifier<List<ReactionEvent>>([]);
      await _pumpOverlay(tester, reactions);

      reactions.value = [(emoji: '🥳', ts: 1, userId: 'u1')];
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('🥳'), findsOneWidget);

      // durationMs is randomized in [3600, 5000) — settle well past the
      // maximum possible duration.
      await tester.pump(const Duration(seconds: 6));
      expect(find.text('🥳'), findsNothing);
    },
  );

  testWidgets(
    'a reaction already present at mount does NOT replay (reconnect mid-round)',
    (tester) async {
      final reactions = ValueNotifier<List<ReactionEvent>>([
        (emoji: '💯', ts: 3, userId: 'u3'),
      ]);
      await _pumpOverlay(tester, reactions);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('💯'), findsNothing);
    },
  );

  testWidgets('duplicate event handling: the SAME ts is never spawned twice', (
    tester,
  ) async {
    final reactions = ValueNotifier<List<ReactionEvent>>([]);
    await _pumpOverlay(tester, reactions);

    reactions.value = [(emoji: '🥳', ts: 1, userId: 'u1')];
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('🥳'), findsOneWidget);

    // A rebuild that hands back the exact same event (same ts) — e.g. an
    // unrelated provider notifyListeners() — must not spawn a second
    // flight for it.
    reactions.value = [(emoji: '🥳', ts: 1, userId: 'u1')];
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('🥳'), findsOneWidget);
  });

  testWidgets('a mapped emoji reaction renders an animated emoji', (
    tester,
  ) async {
    final reactions = ValueNotifier<List<ReactionEvent>>([]);
    await _pumpOverlay(tester, reactions);
    reactions.value = [(emoji: '😂', ts: 1, userId: 'u1')];
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(AnimatedEmoji), findsOneWidget);
  });

  testWidgets(
    'a plain emoji reaction shows the icon and name but NO user avatar',
    (tester) async {
      final reactions = ValueNotifier<List<ReactionEvent>>([]);
      await _pumpOverlay(tester, reactions);
      reactions.value = [(emoji: '🥳', ts: 1, userId: 'u1')];
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('🥳'), findsOneWidget);
      expect(find.text('name-u1'), findsOneWidget);
      expect(find.byType(UserAvatar), findsNothing);
    },
  );

  testWidgets(
    'an animated (Lottie) emoji reaction also shows no avatar, just the '
    'animated glyph and name',
    (tester) async {
      final reactions = ValueNotifier<List<ReactionEvent>>([]);
      await _pumpOverlay(tester, reactions);
      // '😂' IS in kAnimatedEmojiMap — use it to confirm an animated
      // (Lottie) reaction carries no avatar either.
      reactions.value = [(emoji: '😂', ts: 1, userId: 'u1')];
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AnimatedEmoji), findsOneWidget);
      expect(find.text('name-u1'), findsOneWidget);
      expect(find.byType(UserAvatar), findsNothing);
    },
  );

  testWidgets('an avatar reaction resolves the reactor, not the viewer', (
    tester,
  ) async {
    final resolvedUserIds = <String>[];
    final reactions = ValueNotifier<List<ReactionEvent>>([]);
    await _pumpOverlay(
      tester,
      reactions,
      resolver: (id) {
        resolvedUserIds.add(id);
        return _member(id);
      },
    );
    reactions.value = [(emoji: 'avatar:laugh', ts: 9, userId: 'reactorX')];
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    // UserAvatar can't fully render a real avatar without assets in a unit
    // test — consume that expected render error.
    tester.takeException();
    expect(resolvedUserIds, contains('reactorX'));
    expect(resolvedUserIds, isNot(contains('viewer')));
    // An avatar-token reaction is the one case that DOES render a
    // UserAvatar — as the reaction graphic itself, not an identity photo.
    expect(find.byType(UserAvatar), findsOneWidget);
  });

  testWidgets('the overlay never intercepts taps outside an actual reaction '
      '(no blanket hit-testing over empty space)', (tester) async {
    var gameControlTapped = false;
    const gameControlKey = Key('game-control');
    final reactions = ValueNotifier<List<ReactionEvent>>([]);
    await tester.pumpWidget(
      MaterialApp(
        theme: _testTheme(),
        home: Scaffold(
          body: Stack(
            children: [
              GestureDetector(
                key: gameControlKey,
                behavior: HitTestBehavior.opaque,
                onTap: () => gameControlTapped = true,
                child: const SizedBox.expand(),
              ),
              Positioned.fill(
                child: ValueListenableBuilder<List<ReactionEvent>>(
                  valueListenable: reactions,
                  builder: (_, list, _) => AnimatedReactionOverlay(
                    reactions: list,
                    avatarResolver: _member,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    reactions.value = [(emoji: '🥳', ts: 1, userId: 'u1')];
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap the game-control layer itself (not a raw offset) — this must
    // still receive the tap through the reaction overlay stacked on top
    // of it, since a bare Positioned reaction with no content at this
    // point must never absorb it.
    await tester.tap(find.byKey(gameControlKey));
    expect(gameControlTapped, isTrue);
  });

  group('item 1 (this pass) — reactor name has no unwanted underline/line '
      'artifacts', () {
    testWidgets(
      'normal (emoji) reaction: the name Text has decoration explicitly '
      'set to none, not left to inherit an ambient DefaultTextStyle',
      (tester) async {
        final reactions = ValueNotifier<List<ReactionEvent>>([]);
        await _pumpOverlay(tester, reactions);

        reactions.value = [(emoji: '🥳', ts: 1, userId: 'u1')];
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final nameText = tester.widget<Text>(find.text('name-u1'));
        expect(nameText.style?.decoration, TextDecoration.none);
      },
    );

    testWidgets('avatar reaction: the name Text ALSO has decoration explicitly '
        'set to none', (tester) async {
      final reactions = ValueNotifier<List<ReactionEvent>>([]);
      await _pumpOverlay(tester, reactions);

      reactions.value = [
        (emoji: '${AvatarConfig.reactionPrefix}wave', ts: 1, userId: 'u1'),
      ];
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final nameText = tester.widget<Text>(find.text('name-u1'));
      expect(nameText.style?.decoration, TextDecoration.none);
    });

    testWidgets(
      'a DefaultTextStyle ancestor with an underline decoration is never '
      'inherited by the reactor name — the exact bug this pass fixes',
      (tester) async {
        final reactions = ValueNotifier<List<ReactionEvent>>([]);
        await tester.pumpWidget(
          MaterialApp(
            theme: _testTheme(),
            home: Scaffold(
              body: DefaultTextStyle(
                // Simulates whatever ambient style previously leaked an
                // underline into the reactor name — the fix must make
                // this irrelevant regardless of what an ancestor sets.
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.double,
                  color: Colors.black,
                ),
                child: Stack(
                  children: [
                    const SizedBox.expand(),
                    Positioned.fill(
                      child: ValueListenableBuilder<List<ReactionEvent>>(
                        valueListenable: reactions,
                        builder: (_, list, _) => AnimatedReactionOverlay(
                          reactions: list,
                          avatarResolver: _member,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        reactions.value = [(emoji: '🥳', ts: 1, userId: 'u1')];
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final nameText = tester.widget<Text>(find.text('name-u1'));
        expect(nameText.style?.decoration, TextDecoration.none);
      },
    );
  });
}
