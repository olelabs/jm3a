// Regression coverage for item 9 — reporting a user from their profile.
// FriendsRepository is a hard singleton wrapping Supabase.instance.client
// directly (same pattern as PackRepository — confirmed empirically
// elsewhere in this suite), so it can't be constructed for real in a bare
// test. `implements` (unlike `extends`) never invokes the target class's
// constructor, so a hand-written fake sidesteps that entirely — same
// established workaround as pack_filter_combination_test.dart's
// _FakePackRepository.
//
// FriendsProvider.onUserLoggedIn additionally touches PresenceService
// .instance (a second hard Supabase singleton) — a test subclass
// overrides it to a no-op so onAuthChanged can still be exercised for
// real (setting currentUserId) without tripping that landmine.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/errors/failures.dart';
import 'package:jma3a/features/friends/presentation/friends_provider.dart';

class _ReportCall {
  _ReportCall(this.targetUserId, this.reporterId, this.reason, this.details);
  final String targetUserId;
  final String reporterId;
  final String reason;
  final String? details;
}

class _FakeFriendsRepository implements FriendsRepository {
  final List<_ReportCall> reportCalls = [];
  final List<String> blockedUserIds = [];
  bool throwOnReport = false;

  @override
  Future<void> reportUser({
    required String targetUserId,
    required String reporterId,
    required String reason,
    String? details,
  }) async {
    // BaseProvider.runAsync only catches `Failure` (see guardedCall's role
    // translating raw exceptions before they ever reach a provider) — a
    // plain Exception would propagate uncaught, which isn't what a real
    // repository call surfaces.
    if (throwOnReport) throw const ServerFailure();
    reportCalls.add(_ReportCall(targetUserId, reporterId, reason, details));
  }

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    blockedUserIds.add(blockedId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

/// Skips FriendsProvider's real onUserLoggedIn (which touches
/// PresenceService.instance, a second hard Supabase singleton, plus
/// realtime CDC subscriptions and repo loads) so onAuthChanged can still
/// be exercised for real — this only replaces the FriendsProvider-specific
/// side effects, not BaseProvider's own currentUserId-setting logic.
class _TestFriendsProvider extends FriendsProvider {
  _TestFriendsProvider(FriendsRepository repo)
    : super(friendsRepository: repo);

  @override
  void onUserLoggedIn(String userId) {
    // no-op — deliberately skips PresenceService/CDC/repo loads.
  }
}

void main() {
  group('FriendsProvider.reportUser (Item 9)', () {
    test('returns false and never calls the repository when signed out', () async {
      final repo = _FakeFriendsRepository();
      final provider = _TestFriendsProvider(repo);
      // currentUserId defaults to null until onAuthChanged runs.
      final ok = await provider.reportUser(
        targetUserId: 'target-1',
        reason: 'harassment',
      );
      expect(ok, isFalse);
      expect(repo.reportCalls, isEmpty);
    });

    test('forwards target/reporter/reason/details and returns true on success', () async {
      final repo = _FakeFriendsRepository();
      final provider = _TestFriendsProvider(repo)..onAuthChanged('reporter-1');

      final ok = await provider.reportUser(
        targetUserId: 'target-1',
        reason: 'impersonation',
        details: 'Pretending to be someone else',
      );

      expect(ok, isTrue);
      expect(repo.reportCalls, hasLength(1));
      expect(repo.reportCalls.single.targetUserId, 'target-1');
      expect(repo.reportCalls.single.reporterId, 'reporter-1');
      expect(repo.reportCalls.single.reason, 'impersonation');
      expect(repo.reportCalls.single.details, 'Pretending to be someone else');
    });

    test('a repository failure surfaces as false, never a crash', () async {
      final repo = _FakeFriendsRepository()..throwOnReport = true;
      final provider = _TestFriendsProvider(repo)..onAuthChanged('reporter-1');

      final ok = await provider.reportUser(
        targetUserId: 'target-1',
        reason: 'spam',
      );
      expect(ok, isFalse);
    });

    test('reportUser never touches blockUser — Report and Block stay independent '
        '(Report & Block is the caller composing both, not a hidden coupling)', () async {
      final repo = _FakeFriendsRepository();
      final provider = _TestFriendsProvider(repo)..onAuthChanged('reporter-1');

      await provider.reportUser(targetUserId: 'target-1', reason: 'other');
      expect(repo.blockedUserIds, isEmpty);
    });
  });
}
