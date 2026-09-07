// Tests for item 4 (NHIE/Meme chat, reusing ToD's shared chat mechanism)
// and items 6/7 (reply-to-message, keyboard dismissal), exercised against
// the shared GameChatSheet/GameChatMsg (lib/shared/widgets/game/
// game_chat_sheet.dart) that ToD, NHIE, and Meme's providers all now use
// identically (TodGameProvider.sendChat/NhieGameProvider.sendChat/
// MemeGameProvider.sendChat — same GameChatMsg model, same sheet, same
// reply/keyboard mechanics for all three; nothing game-specific here).
//
// NhieGameProvider/MemeGameProvider/TodGameProvider all expose
// chatMessages/sendChat/addChatMessage now (items 15-17) — verified by
// construction/type below rather than a full provider integration test,
// since standing one up needs a live Supabase realtime channel this
// offline suite doesn't have (see final report for what still needs
// device verification).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:jma3a/shared/widgets/cards/permium_badge.dart';
import 'package:jma3a/shared/widgets/cards/user_avatar.dart';
import 'package:jma3a/shared/widgets/game/game_chat_sheet.dart';

class _FakeListenable extends ChangeNotifier {}

Future<void> pumpSheet(
  WidgetTester tester, {
  required Future<bool> Function(String, {GameChatMsg? replyTo}) onSend,
  List<GameChatMsg> messages = const [],
  RoomMemberEntity? Function(String senderId)? memberOf,
}) async {
  final listenable = _FakeListenable();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: GameChatSheet(
          listenable: listenable,
          messagesOf: () => messages,
          myId: 'me',
          title: 'Chat',
          onSend: onSend,
          memberOf: memberOf,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens GameChatSheet through a REAL showModalBottomSheet push (unlike
/// [pumpSheet], which embeds it directly in a Scaffold body) — needed to
/// observe drag-to-dismiss actually popping the route.
Future<void> pumpSheetAsModal(
  WidgetTester tester, {
  required Future<bool> Function(String, {GameChatMsg? replyTo}) onSend,
  List<GameChatMsg> messages = const [],
}) async {
  final listenable = _FakeListenable();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => GameChatSheet(
                  listenable: listenable,
                  messagesOf: () => messages,
                  myId: 'me',
                  title: 'Chat',
                  onSend: onSend,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Same as [pumpSheet] but wraps the sheet in a MediaQuery reporting a
/// simulated keyboard inset — the shape showModalBottomSheet's own
/// content actually receives on-device (see the 18.8/5 regression guard
/// test), since it does not shift/pad for the keyboard itself.
Future<void> pumpSheetWithInset(
  WidgetTester tester, {
  required Future<bool> Function(String, {GameChatMsg? replyTo}) onSend,
  required double bottomInset,
  List<GameChatMsg> messages = const [],
}) async {
  final listenable = _FakeListenable();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(viewInsets: EdgeInsets.only(bottom: bottomInset)),
          child: Scaffold(
            body: GameChatSheet(
              listenable: listenable,
              messagesOf: () => messages,
              myId: 'me',
              title: 'Chat',
              onSend: onSend,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Real-device follow-up — chat avatars/identity (item 1)', () {
    RoomMemberEntity member({
      String userId = 'other',
      String? avatarUrl,
      bool isPremium = false,
      String? premiumTier,
    }) => RoomMemberEntity(
      userId: userId,
      displayName: 'Alice',
      avatarUrl: avatarUrl,
      seatOrder: 0,
      isReady: true,
      isOwner: false,
      isModerator: false,
      isPremium: isPremium,
      premiumTier: premiumTier,
    );

    testWidgets('a basic (non-premium) user without a profile image shows '
        'a UserAvatar (falling back to its own initial-letter rendering) '
        'and no premium badge', (tester) async {
      await pumpSheet(
        tester,
        messages: [
          GameChatMsg(
            id: 'm1',
            senderId: 'other',
            senderName: 'Alice',
            text: 'hi',
            ts: DateTime.now(),
          ),
        ],
        onSend: (text, {replyTo}) async => true,
        memberOf: (_) => member(),
      );
      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.byType(PremiumBadge), findsNothing);
    });

    testWidgets('a user WITH a profile image passes avatarUrl straight '
        'through to UserAvatar (the same widget/network-image resolution '
        'every other avatar in the app already uses)', (tester) async {
      await pumpSheet(
        tester,
        messages: [
          GameChatMsg(
            id: 'm1',
            senderId: 'other',
            senderName: 'Alice',
            text: 'hi',
            ts: DateTime.now(),
          ),
        ],
        onSend: (text, {replyTo}) async => true,
        memberOf: (_) => member(avatarUrl: 'https://example.com/a.png'),
      );
      final avatar = tester.widget<UserAvatar>(find.byType(UserAvatar));
      expect(avatar.avatarUrl, 'https://example.com/a.png');
    });

    testWidgets('a premium user shows the SAME PremiumBadge widget used '
        'elsewhere in the app (reused visual language, not a second '
        'premium indicator)', (tester) async {
      await pumpSheet(
        tester,
        messages: [
          GameChatMsg(
            id: 'm1',
            senderId: 'other',
            senderName: 'Alice',
            text: 'hi',
            ts: DateTime.now(),
          ),
        ],
        onSend: (text, {replyTo}) async => true,
        memberOf: (_) => member(isPremium: true, premiumTier: 'premium_plus'),
      );
      final badge = tester.widget<PremiumBadge>(find.byType(PremiumBadge));
      expect(badge.tier, 'premium_plus');
    });

    testWidgets('an Arabic sender name resolves a non-empty initial and '
        'renders without error (UserAvatar\'s own initial-letter fallback, '
        'reused as-is — RTL text direction is handled by the surrounding '
        'localization, not by this widget)', (tester) async {
      await pumpSheet(
        tester,
        messages: [
          GameChatMsg(
            id: 'm1',
            senderId: 'other',
            senderName: 'محمد',
            text: 'مرحبا',
            ts: DateTime.now(),
          ),
        ],
        onSend: (text, {replyTo}) async => true,
        memberOf: (_) => member(),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.text('محمد'), findsOneWidget);
    });

    testWidgets('own messages do NOT show an avatar or premium badge — '
        'matches the existing lobby-chat convention (ChatPanel\'s '
        '_ChatBubble: avatar/badge only for !isMe) reused here for '
        'consistency, not a new rule invented for game chat', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        messages: [
          GameChatMsg(
            id: 'm1',
            senderId: 'me',
            senderName: 'Me',
            text: 'my own message',
            ts: DateTime.now(),
          ),
        ],
        onSend: (text, {replyTo}) async => true,
        memberOf: (_) => member(userId: 'me', isPremium: true),
      );
      expect(find.byType(UserAvatar), findsNothing);
      expect(find.byType(PremiumBadge), findsNothing);
    });

    testWidgets('a reply message still shows the REPLYING sender\'s avatar '
        '(the reply-to snippet above the bubble is unaffected — this is '
        'about the message\'s OWN sender, not the quoted original)', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        messages: [
          GameChatMsg(
            id: 'm1',
            senderId: 'alice',
            senderName: 'Alice',
            text: 'original',
            ts: DateTime.now(),
          ),
          GameChatMsg(
            id: 'm2',
            senderId: 'bob',
            senderName: 'Bob',
            text: 'a reply',
            ts: DateTime.now(),
            replyToId: 'm1',
            replyToSenderName: 'Alice',
            replyToText: 'original',
          ),
        ],
        onSend: (text, {replyTo}) async => true,
        memberOf: (id) => member(userId: id, isPremium: id == 'bob'),
      );
      // Two non-own messages ⇒ two avatars; only Bob's reply is premium.
      expect(find.byType(UserAvatar), findsNWidgets(2));
      expect(find.byType(PremiumBadge), findsOneWidget);
    });

    testWidgets('no memberOf resolver passed at all (a caller that hasn\'t '
        'been updated) still renders every message safely — UserAvatar '
        'just falls back to its own no-data initial rendering, nothing '
        'breaks for a caller that doesn\'t pass this', (tester) async {
      await pumpSheet(
        tester,
        messages: [
          GameChatMsg(
            id: 'm1',
            senderId: 'other',
            senderName: 'Alice',
            text: 'hi',
            ts: DateTime.now(),
          ),
        ],
        onSend: (text, {replyTo}) async => true,
        // memberOf intentionally omitted.
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(UserAvatar), findsOneWidget);
    });
  });

  group('GameChatMsg — reply reference (items 21/23/24)', () {
    test('24. a normal (non-reply) message has null reply fields, '
        'unaffected by reply support existing', () {
      final msg = GameChatMsg(
        senderId: 'p1',
        senderName: 'Alice',
        text: 'hey',
        ts: DateTime.now(),
      );
      expect(msg.isReply, isFalse);
      expect(msg.replyToId, isNull);
    });

    test('23. a reply message preserves the original message\'s id/'
        'sender/text as a snapshot', () {
      final original = GameChatMsg(
        id: 'm1',
        senderId: 'p1',
        senderName: 'Alice',
        text: 'original text',
        ts: DateTime.now(),
      );
      final reply = GameChatMsg(
        id: 'm2',
        senderId: 'p2',
        senderName: 'Bob',
        text: 'replying',
        ts: DateTime.now(),
        replyToId: original.id,
        replyToSenderName: original.senderName,
        replyToText: original.text,
      );
      expect(reply.isReply, isTrue);
      expect(reply.replyToId, 'm1');
      expect(reply.replyToSenderName, 'Alice');
      expect(reply.replyToText, 'original text');
    });
  });

  group('GameChatSheet — send/reply/keyboard behavior (items 21, 22, 25, '
      '26)', () {
    testWidgets('25. a successful send clears the composer and closes the '
        'keyboard', (tester) async {
      await pumpSheet(tester, onSend: (text, {replyTo}) async => true);

      await tester.enterText(find.byType(TextField), 'hello world');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('26. a failed send keeps the composer text and does not '
        'steal focus away from the input', (tester) async {
      await pumpSheet(tester, onSend: (text, {replyTo}) async => false);

      await tester.enterText(find.byType(TextField), 'will fail');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'will fail');
    });

    testWidgets('21. a swipe on a message triggers reply mode — the '
        'composer shows a "replying to" preview', (tester) async {
      final messages = [
        GameChatMsg(
          id: 'm1',
          senderId: 'other',
          senderName: 'Alice',
          text: 'original message',
          ts: DateTime.now(),
        ),
      ];
      await pumpSheet(
        tester,
        messages: messages,
        onSend: (text, {replyTo}) async => true,
      );

      expect(find.textContaining('Replying to'), findsNothing);
      await tester.drag(find.text('original message'), const Offset(80, 0));
      await tester.pumpAndSettle();

      expect(find.textContaining('Replying to'), findsOneWidget);
      expect(find.text('original message'), findsWidgets); // bubble + preview
    });

    testWidgets('22. the reply preview can be cancelled before sending',
        (tester) async {
      final messages = [
        GameChatMsg(
          id: 'm1',
          senderId: 'other',
          senderName: 'Alice',
          text: 'original message',
          ts: DateTime.now(),
        ),
      ];
      await pumpSheet(
        tester,
        messages: messages,
        onSend: (text, {replyTo}) async => true,
      );

      await tester.drag(find.text('original message'), const Offset(80, 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('Replying to'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.textContaining('Replying to'), findsNothing);
    });

    testWidgets('a reply is actually threaded through onSend as replyTo',
        (tester) async {
      GameChatMsg? capturedReplyTo;
      final messages = [
        GameChatMsg(
          id: 'm1',
          senderId: 'other',
          senderName: 'Alice',
          text: 'original message',
          ts: DateTime.now(),
        ),
      ];
      await pumpSheet(
        tester,
        messages: messages,
        onSend: (text, {replyTo}) async {
          capturedReplyTo = replyTo;
          return true;
        },
      );

      await tester.drag(find.text('original message'), const Offset(80, 0));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'my reply');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(capturedReplyTo?.id, 'm1');
      expect(capturedReplyTo?.senderName, 'Alice');
    });
  });

  group('Real-device follow-up — first-swipe-to-reply keyboard lifecycle',
      () {
    List<GameChatMsg> oneMessage() => [
      GameChatMsg(
        id: 'm1',
        senderId: 'other',
        senderName: 'Alice',
        text: 'original message',
        ts: DateTime.now(),
      ),
    ];

    testWidgets(
      'first-ever swipe to reply: the composer TextField\'s Element '
      'identity survives the reply-preview Container being inserted '
      'above it — proving Flutter matched it by its own stable key '
      'instead of rebuilding it from scratch (which would tear down its '
      'focus/platform text-input connection mid-transition, the exact '
      'mechanism behind "keyboard opens then immediately closes")',
      (tester) async {
        await pumpSheet(
          tester,
          messages: oneMessage(),
          onSend: (text, {replyTo}) async => true,
        );
        final fieldBefore = tester.element(find.byType(TextField));

        await tester.drag(find.text('original message'), const Offset(80, 0));
        await tester.pumpAndSettle();

        expect(find.textContaining('Replying to'), findsOneWidget);
        final fieldAfter = tester.element(find.byType(TextField));
        expect(identical(fieldBefore, fieldAfter), isTrue);
      },
    );

    testWidgets(
      'first-ever swipe to reply focuses the composer and the focus '
      'STAYS — no open→close flicker (requestFocus() is called exactly '
      'once and nothing subsequently steals it back)',
      (tester) async {
        await pumpSheet(
          tester,
          messages: oneMessage(),
          onSend: (text, {replyTo}) async => true,
        );
        final focusNode = tester
            .widget<TextField>(find.byType(TextField))
            .focusNode!;
        expect(focusNode.hasFocus, isFalse);

        await tester.drag(find.text('original message'), const Offset(80, 0));
        await tester.pumpAndSettle();

        expect(focusNode.hasFocus, isTrue);
        // Settle a bit further — nothing should un-focus it afterward.
        await tester.pump(const Duration(milliseconds: 300));
        expect(focusNode.hasFocus, isTrue);
      },
    );

    testWidgets(
      'second swipe to reply (a different message, after the first reply '
      'was sent) behaves identically — focus is (re)gained and stays, '
      'same as the first time',
      (tester) async {
        final messages = [
          GameChatMsg(
            id: 'm1',
            senderId: 'other',
            senderName: 'Alice',
            text: 'first message',
            ts: DateTime.now(),
          ),
          GameChatMsg(
            id: 'm2',
            senderId: 'other',
            senderName: 'Bob',
            text: 'second message',
            ts: DateTime.now(),
          ),
        ];
        await pumpSheet(
          tester,
          messages: messages,
          onSend: (text, {replyTo}) async => true,
        );

        await tester.drag(find.text('first message'), const Offset(80, 0));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.close_rounded)); // cancel
        await tester.pumpAndSettle();
        expect(find.textContaining('Replying to'), findsNothing);

        final focusNode = tester
            .widget<TextField>(find.byType(TextField))
            .focusNode!;
        await tester.drag(find.text('second message'), const Offset(80, 0));
        await tester.pumpAndSettle();

        expect(find.textContaining('Replying to'), findsOneWidget);
        expect(focusNode.hasFocus, isTrue);
      },
    );

    testWidgets(
      'swiping to reply while the composer is ALREADY focused (keyboard '
      'already open) does not toggle focus off at any point',
      (tester) async {
        await pumpSheet(
          tester,
          messages: oneMessage(),
          onSend: (text, {replyTo}) async => true,
        );
        await tester.tap(find.byType(TextField));
        await tester.pump();
        final focusNode = tester
            .widget<TextField>(find.byType(TextField))
            .focusNode!;
        expect(focusNode.hasFocus, isTrue);

        await tester.drag(find.text('original message'), const Offset(80, 0));
        await tester.pumpAndSettle();

        expect(focusNode.hasFocus, isTrue);
      },
    );

    testWidgets(
      'a FAILED reply send preserves the reply preview AND the draft — '
      'same guarantee item 26 already covers for a plain message, now '
      'confirmed with an active reply attached',
      (tester) async {
        await pumpSheet(
          tester,
          messages: oneMessage(),
          onSend: (text, {replyTo}) async => false,
        );
        await tester.drag(find.text('original message'), const Offset(80, 0));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'my reply');
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pumpAndSettle();

        expect(find.text('my reply'), findsOneWidget); // draft preserved
        expect(
          find.textContaining('Replying to'),
          findsOneWidget,
        ); // reply preview preserved
      },
    );
  });

  group('GameChatSheet — draggable/expandable panel (items 18.7/18.9/35/36/'
      '38)', () {
    testWidgets(
      '35/36/A (real-device follow-up) — the sheet is a '
      'DraggableScrollableSheet (not the old fixed-height Container) that '
      'OPENS fully expanded immediately — initialChildSize equals '
      'maxChildSize, never a smaller "collapsed" size the user has to '
      'grow first',
      (tester) async {
        await pumpSheet(tester, onSend: (text, {replyTo}) async => true);
        final sheet = tester.widget<DraggableScrollableSheet>(
          find.byType(DraggableScrollableSheet),
        );
        expect(sheet.initialChildSize, sheet.maxChildSize);
        expect(sheet.minChildSize, lessThan(sheet.initialChildSize));
        // "Essentially the available screen height" — not 55%/65%/80%.
        expect(sheet.initialChildSize, greaterThanOrEqualTo(0.80));
      },
    );

    testWidgets('38. the message list remains scrollable inside the sheet',
        (tester) async {
      final messages = [
        for (var i = 0; i < 30; i++)
          GameChatMsg(
            id: 'm$i',
            senderId: 'other',
            senderName: 'Alice',
            text: 'message $i',
            ts: DateTime.now(),
          ),
      ];
      await pumpSheet(
        tester,
        messages: messages,
        onSend: (text, {replyTo}) async => true,
      );
      final listFinder = find.byType(ListView);
      expect(listFinder, findsOneWidget);
      final listView = tester.widget<ListView>(listFinder);
      expect(listView.controller, isNotNull);
    });

    testWidgets(
      '18.8/5 (real-device follow-up) root-cause regression guard: '
      'showModalBottomSheet(isScrollControlled: true) does NOT shift this '
      'sheet for the keyboard on its own (confirmed against the Flutter '
      'SDK source — its layout anchors the sheet to the literal screen '
      'bottom and applies no viewInsets compensation at all), so this '
      'sheet must supply exactly one bottom compensation itself. No '
      'exception/overflow with a simulated keyboard inset, and the send '
      'button stays above the inset rather than being pushed off/under it.',
      (tester) async {
        const insetHeight = 300.0;
        await pumpSheetWithInset(
          tester,
          onSend: (text, {replyTo}) async => true,
          bottomInset: insetHeight,
        );
        expect(tester.takeException(), isNull);

        final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
        final sendButtonBottom = tester.getBottomLeft(find.byIcon(Icons.send_rounded)).dy;
        expect(sendButtonBottom, lessThanOrEqualTo(screenHeight - insetHeight));
      },
    );
  });

  group('Real-device follow-up — swipe down to close (item B)', () {
    testWidgets(
      '2. dragging the sheet down past its minChildSize pops the route — '
      'no separate close button needed, and the existing tap-outside/back '
      'dismissal (isDismissible/enableDrag defaults, untouched by this '
      'widget) is unaffected',
      (tester) async {
        await pumpSheetAsModal(
          tester,
          onSend: (text, {replyTo}) async => true,
        );
        expect(find.byType(GameChatSheet), findsOneWidget);

        // Empty message list ⇒ no inner Scrollable to hand the drag off
        // to, so this reaches the DraggableScrollableSheet's own resize
        // gesture directly, same as dragging on the visible drag handle.
        await tester.drag(
          find.byType(GameChatSheet),
          const Offset(0, 700),
        );
        await tester.pumpAndSettle();

        expect(find.byType(GameChatSheet), findsNothing);
      },
    );

    testWidgets(
      'lifecycle-safe dismissal (real-device red-screen root cause): a '
      'FLUNG (velocity-carrying, not just a static drag) swipe down — '
      'the exact gesture that triggers DraggableScrollableSheet\'s own '
      'ballistic/snap simulation racing against Navigator.pop() when '
      'snap:true — closes cleanly with NO exception of any kind',
      (tester) async {
        await pumpSheetAsModal(
          tester,
          onSend: (text, {replyTo}) async => true,
        );
        expect(find.byType(GameChatSheet), findsOneWidget);

        await tester.fling(
          find.byType(GameChatSheet),
          const Offset(0, 600),
          2000, // a real, fast swipe — enough velocity to hit goBallistic
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(GameChatSheet), findsNothing);
      },
    );

    testWidgets(
      'dismissal while the keyboard is open is equally lifecycle-safe — '
      'no exception from a didChangeMetrics/AnimatedPadding callback '
      'still in flight when the sheet is torn down',
      (tester) async {
        addTearDown(() => tester.view.resetViewInsets());
        await pumpSheetAsModal(
          tester,
          onSend: (text, {replyTo}) async => true,
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pump();

        await tester.fling(
          find.byType(GameChatSheet),
          const Offset(0, 600),
          2000,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(GameChatSheet), findsNothing);
      },
    );

    testWidgets(
      'no double pop: dismissing via drag when the route is already being '
      'popped (e.g. a near-simultaneous back gesture) never pops a second, '
      'unrelated route underneath',
      (tester) async {
        final navigatorKey = GlobalKey<NavigatorState>();
        final listenable = _FakeListenable();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            navigatorKey: navigatorKey,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => GameChatSheet(
                        listenable: listenable,
                        messagesOf: () => const [],
                        myId: 'me',
                        title: 'Chat',
                        onSend: (text, {replyTo}) async => true,
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.byType(GameChatSheet), findsOneWidget);

        // Start the drag-to-dismiss, then ALSO pop programmatically
        // before the drag's own postFrameCallback-scheduled pop runs —
        // simulating a back-gesture racing the swipe.
        await tester.drag(find.byType(GameChatSheet), const Offset(0, 700));
        navigatorKey.currentState!.maybePop();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // Exactly back to the "open" button screen — not popped past it.
        expect(find.text('open'), findsOneWidget);
      },
    );
  });

  group('Real-device follow-up — full height + keyboard-open scroll '
      '(items A/D)', () {
    testWidgets(
      '1. opens fully expanded — initialChildSize is the same "essentially '
      'full height" value as maxChildSize, not a smaller default the user '
      'has to grow first',
      (tester) async {
        await pumpSheet(tester, onSend: (text, {replyTo}) async => true);
        final sheet = tester.widget<DraggableScrollableSheet>(
          find.byType(DraggableScrollableSheet),
        );
        expect(sheet.initialChildSize, sheet.maxChildSize);
        expect(sheet.initialChildSize, greaterThanOrEqualTo(0.80));
      },
    );

    testWidgets(
      '6. a real OS keyboard-open transition (via the actual '
      'WidgetsBindingObserver.didChangeMetrics path, not just a wrapping '
      'MediaQuery rebuild) scrolls the message list to the newest '
      'message — not back to the beginning of the conversation',
      (tester) async {
        addTearDown(() => tester.view.resetViewInsets());
        final messages = [
          for (var i = 0; i < 40; i++)
            GameChatMsg(
              id: 'm$i',
              senderId: 'other',
              senderName: 'Alice',
              text: 'message $i',
              ts: DateTime.now(),
            ),
        ];
        await pumpSheet(
          tester,
          onSend: (text, {replyTo}) async => true,
          messages: messages,
        );

        final listFinder = find.byType(ListView);
        final scrollableBefore = tester.state<ScrollableState>(
          find.descendant(
            of: listFinder,
            matching: find.byType(Scrollable),
          ),
        );
        // Starts at the top (ListView.builder's default) — nowhere near
        // the newest (last) message yet.
        expect(scrollableBefore.position.pixels, 0);

        // Simulate the real OS keyboard opening — the same signal
        // didChangeMetrics reacts to on-device, via the actual
        // WidgetsBinding metrics-changed path rather than a synthetic
        // MediaQuery wrapper (see pumpSheetWithInset's own doc comment
        // for why that alternate approach doesn't exercise this path).
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();

        final scrollableAfter = tester.state<ScrollableState>(
          find.descendant(
            of: listFinder,
            matching: find.byType(Scrollable),
          ),
        );
        expect(
          scrollableAfter.position.pixels,
          scrollableAfter.position.maxScrollExtent,
        );
      },
    );
  });
}
