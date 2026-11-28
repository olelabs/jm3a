// Pre-release audit — Add Friend regression coverage.
//
// Root cause being guarded: FriendsProvider.sendFriendRequest returned
// `runAsync(...) != null`, and runAsync's result for a closure with no
// return value is always null, so every SUCCESSFUL send reported false.
// The Explore card only flipped to "Request Sent" on true, so it stayed
// "Add Friend" forever. Separately, FriendsRepository.sendFriendRequest
// threw a generic ConflictFailure for ANY existing row, so a previously
// rejected pair (shown as "Add Friend") could never re-request.
//
// FriendsRepository is a hard Supabase singleton; `implements` sidesteps
// its constructor (same workaround as friends_report_user_test.dart).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/errors/failures.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/features/friends/presentation/friends_provider.dart';
import 'package:jma3a/shared/widgets/cards/explore_person_card.dart';

class _FakeFriendsRepository implements FriendsRepository {
  FriendRequestOutcome nextOutcome = FriendRequestOutcome.sent;
  Failure? nextFailure;
  Completer<void>? gate;
  int sendCalls = 0;
  int cancelCalls = 0;
  List<FriendEntity> sent = [];

  @override
  Future<FriendRequestOutcome> sendFriendRequest({
    required String requesterId,
    required String addresseeId,
  }) async {
    sendCalls++;
    if (gate != null) await gate!.future;
    if (nextFailure != null) throw nextFailure!;
    if (nextOutcome == FriendRequestOutcome.sent ||
        nextOutcome == FriendRequestOutcome.alreadySent) {
      sent = [
        FriendEntity(
          userId: addresseeId,
          displayName: 'B',
          status: FriendshipStatus.pending,
          isRequester: true,
        ),
      ];
    }
    return nextOutcome;
  }

  @override
  Future<void> cancelRequest({
    required String requesterId,
    required String addresseeId,
  }) async {
    cancelCalls++;
    sent = [];
  }

  @override
  Future<List<FriendEntity>> getSentRequests(String userId) async => sent;

  @override
  Future<List<FriendEntity>> getPendingRequests(String userId) async => [];

  @override
  Future<List<FriendEntity>> getFriends(String userId) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _TestFriendsProvider extends FriendsProvider {
  _TestFriendsProvider(FriendsRepository repo)
    : super(friendsRepository: repo);

  @override
  void onUserLoggedIn(String userId) {}
}

FriendEntity _row(FriendshipStatus status, {required bool iRequested}) =>
    FriendEntity(
      userId: 'b',
      displayName: '',
      status: status,
      isRequester: iRequested,
    );

void main() {
  // AppLogger reads dotenv; provider load helpers log on error.
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  group('resolveFriendRequestAction (existing-relationship cases)', () {
    test('no row → insert', () {
      expect(resolveFriendRequestAction(null), FriendRequestAction.insert);
    });
    test('rejected row (either direction) → replace, not a dead end', () {
      expect(
        resolveFriendRequestAction(
          _row(FriendshipStatus.rejected, iRequested: true),
        ),
        FriendRequestAction.replaceRejected,
      );
      expect(
        resolveFriendRequestAction(
          _row(FriendshipStatus.rejected, iRequested: false),
        ),
        FriendRequestAction.replaceRejected,
      );
    });
    test('my pending request → alreadySent (no duplicate insert)', () {
      expect(
        resolveFriendRequestAction(
          _row(FriendshipStatus.pending, iRequested: true),
        ),
        FriendRequestAction.alreadySent,
      );
    });
    test('their pending request → incomingPending', () {
      expect(
        resolveFriendRequestAction(
          _row(FriendshipStatus.pending, iRequested: false),
        ),
        FriendRequestAction.incomingPending,
      );
    });
    test('accepted → alreadyFriends; blocked → blocked', () {
      expect(
        resolveFriendRequestAction(
          _row(FriendshipStatus.accepted, iRequested: false),
        ),
        FriendRequestAction.alreadyFriends,
      );
      expect(
        resolveFriendRequestAction(
          _row(FriendshipStatus.blocked, iRequested: true),
        ),
        FriendRequestAction.blocked,
      );
    });
    test('only no-write actions map to a precomputed outcome', () {
      expect(friendRequestOutcomeFor(FriendRequestAction.insert), isNull);
      expect(
        friendRequestOutcomeFor(FriendRequestAction.replaceRejected),
        isNull,
      );
      expect(friendRequestOutcomeFor(FriendRequestAction.blocked), isNull);
      expect(
        friendRequestOutcomeFor(FriendRequestAction.alreadySent),
        FriendRequestOutcome.alreadySent,
      );
      expect(
        friendRequestOutcomeFor(FriendRequestAction.incomingPending),
        FriendRequestOutcome.incomingPending,
      );
      expect(
        friendRequestOutcomeFor(FriendRequestAction.alreadyFriends),
        FriendRequestOutcome.alreadyFriends,
      );
    });
  });

  group('resolveFriendshipButtonState (profile screen)', () {
    FriendshipButtonState resolve({
      FriendshipStatus? status,
      bool requester = false,
      bool sent = false,
      bool incoming = false,
      bool friends = false,
    }) => resolveFriendshipButtonState(
      status: status,
      isFriendshipRequester: requester,
      inSentRequests: sent,
      inIncomingRequests: incoming,
      inFriends: friends,
    );

    test('no relationship → Add Friend', () {
      expect(resolve(), FriendshipButtonState.addFriend);
    });
    test('live pending from me → Request Sent', () {
      expect(
        resolve(status: FriendshipStatus.pending, requester: true),
        FriendshipButtonState.requestSent,
      );
    });
    test('live pending from them → Accept/Reject', () {
      expect(
        resolve(status: FriendshipStatus.pending),
        FriendshipButtonState.respondToRequest,
      );
    });
    test('live accepted → Friends', () {
      expect(
        resolve(status: FriendshipStatus.accepted),
        FriendshipButtonState.friends,
      );
    });
    test(
      'regression: profile has no live status but the request was just sent → '
      'Request Sent, never Add Friend',
      () {
        expect(resolve(sent: true), FriendshipButtonState.requestSent);
        expect(
          resolve(status: FriendshipStatus.rejected, sent: true),
          FriendshipButtonState.requestSent,
        );
      },
    );
    test('rejected with nothing cached → Add Friend (re-requestable)', () {
      expect(
        resolve(status: FriendshipStatus.rejected),
        FriendshipButtonState.addFriend,
      );
    });
    test('cached incoming / friends fall back correctly', () {
      expect(resolve(incoming: true), FriendshipButtonState.respondToRequest);
      expect(resolve(friends: true), FriendshipButtonState.friends);
    });
  });

  group('FriendsProvider.sendFriendRequest', () {
    late _FakeFriendsRepository repo;
    late _TestFriendsProvider provider;

    setUp(() {
      repo = _FakeFriendsRepository();
      provider = _TestFriendsProvider(repo)..onAuthChanged('me');
    });

    test(
      'regression: a successful send returns sent and flips the Explore card',
      () async {
        final outcome = await provider.sendExploreFriendRequest('b');
        expect(outcome, FriendRequestOutcome.sent);
        expect(provider.hasSentExploreRequest('b'), isTrue);
        expect(provider.searchStatuses['b']?.status, FriendshipStatus.pending);
        expect(provider.searchStatuses['b']?.isRequester, isTrue);
        expect(provider.sentRequests.map((r) => r.userId), ['b']);
      },
    );

    test('a failed send returns null, records the failure, claims nothing', () async {
      repo.nextFailure = const ServerFailure();
      final outcome = await provider.sendFriendRequest('b');
      expect(outcome, isNull);
      expect(provider.failure, isA<ServerFailure>());
      expect(provider.hasSentExploreRequest('b'), isFalse);
      expect(provider.searchStatuses.containsKey('b'), isFalse);
    });

    test('a second tap while in flight does not send a duplicate', () async {
      repo.gate = Completer<void>();
      final first = provider.sendFriendRequest('b');
      expect(provider.isSendingFriendRequest('b'), isTrue);
      final second = await provider.sendFriendRequest('b');
      expect(second, isNull);
      repo.gate!.complete();
      expect(await first, FriendRequestOutcome.sent);
      expect(repo.sendCalls, 1);
      expect(provider.isSendingFriendRequest('b'), isFalse);
    });

    test('incoming request is reported, not shown as sent', () async {
      repo.nextOutcome = FriendRequestOutcome.incomingPending;
      expect(
        await provider.sendFriendRequest('b'),
        FriendRequestOutcome.incomingPending,
      );
      expect(provider.hasSentExploreRequest('b'), isFalse);
      expect(provider.searchStatuses['b']?.isRequester, isFalse);
    });

    test('already friends is reported as accepted', () async {
      repo.nextOutcome = FriendRequestOutcome.alreadyFriends;
      expect(
        await provider.sendFriendRequest('b'),
        FriendRequestOutcome.alreadyFriends,
      );
      expect(provider.searchStatuses['b']?.status, FriendshipStatus.accepted);
      expect(provider.hasSentExploreRequest('b'), isFalse);
    });

    test('cancelling clears the Request Sent state everywhere', () async {
      await provider.sendExploreFriendRequest('b');
      await provider.cancelRequest('b');
      expect(repo.cancelCalls, 1);
      expect(provider.hasSentExploreRequest('b'), isFalse);
      expect(provider.sentRequests, isEmpty);
      expect(provider.searchStatuses.containsKey('b'), isFalse);
    });

    test('signed out → never calls the repository', () async {
      final p = _TestFriendsProvider(repo);
      expect(await p.sendFriendRequest('b'), isNull);
      expect(repo.sendCalls, 0);
    });
  });

  group('friendRequestOutcomeMessage', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    test('success and existing-state messages', () {
      expect(
        friendRequestOutcomeMessage(
          l10n,
          FriendRequestOutcome.sent,
          displayName: 'Sara',
        ),
        contains('Friend request sent to Sara'),
      );
      expect(
        friendRequestOutcomeMessage(
          l10n,
          FriendRequestOutcome.alreadySent,
          displayName: 'Sara',
        ),
        contains('already sent Sara'),
      );
      expect(
        friendRequestOutcomeMessage(
          l10n,
          FriendRequestOutcome.incomingPending,
          displayName: 'Sara',
        ),
        contains('Sara already sent you'),
      );
      expect(
        friendRequestOutcomeMessage(
          l10n,
          FriendRequestOutcome.alreadyFriends,
          displayName: 'Sara',
        ),
        contains('are friends'),
      );
    });
    test('failure never claims success', () {
      final generic = friendRequestOutcomeMessage(
        l10n,
        null,
        displayName: 'Sara',
        failure: const ServerFailure(),
      );
      expect(generic, l10n.lobbyCouldNotSendRequest);
      expect(generic.toLowerCase(), isNot(contains('sent to')));
      expect(
        friendRequestOutcomeMessage(
          l10n,
          null,
          displayName: 'Sara',
          failure: const ForbiddenFailure(),
        ),
        l10n.lobbyCannotSendRequest('Sara'),
      );
    });
  });

  group('ExplorePersonCard', () {
    const person = ExplorePerson(
      userId: 'b',
      username: 'sara',
      displayName: 'Sara',
      honestyPoints: 1,
      generalScore: 1,
      rankPosition: 1,
      totalEligible: 1,
      discoveryPoolSize: 1,
    );

    Widget wrap(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

    testWidgets('disabled while sending; Request Sent once sent', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          ExplorePersonCard(
            person: person,
            hasSentRequest: false,
            isSending: true,
            onAddFriend: () => taps++,
          ),
        ),
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      await tester.pumpWidget(
        wrap(
          ExplorePersonCard(
            person: person,
            hasSentRequest: true,
            onAddFriend: () => taps++,
          ),
        ),
      );
      expect(find.text('Request Sent'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(taps, 0);
    });

    testWidgets('Arabic RTL at 320px: sending and sent states lay out cleanly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      const longName = ExplorePerson(
        userId: 'b',
        username: 'a_really_long_username_for_layout',
        displayName: 'عبد الرحمن بن محمد الشنقيطي الطويل جداً',
        honestyPoints: 1234,
        generalScore: 98765,
        rankPosition: 1,
        totalEligible: 1,
        discoveryPoolSize: 1,
      );
      for (final (sending, sent) in [(false, false), (true, false), (false, true)]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ListView(
                children: [
                  ExplorePersonCard(
                    person: longName,
                    hasSentRequest: sent,
                    isSending: sending,
                    onAddFriend: () {},
                  ),
                ],
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: 'sending=$sending sent=$sent');
        expect(
          Directionality.of(tester.element(find.byType(ExplorePersonCard))),
          TextDirection.rtl,
        );
        if (sent) expect(find.text('تم إرسال الطلب'), findsOneWidget);
        if (!sent && !sending) expect(find.text('إضافة صديق'), findsOneWidget);
        if (sending) {
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        }
      }
    });
  });
}
