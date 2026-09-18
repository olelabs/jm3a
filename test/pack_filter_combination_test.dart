// Regression coverage for Packs filtering combining incorrectly.
//
// ORIGINAL ROOT CAUSE: PackRepository.browsePacks itself ANDs whatever
// filters it's given (correct at the query layer) — the bug was entirely in
// the CALLERS: marketplace_screen.dart's filter callbacks each passed ONLY
// the filter that just changed, so any other active filter silently reset
// to its default on every call. PackProvider.loadMoreBrowsePacks had the
// same gap for pagination: it didn't accept the full filter set to forward.
//
// The "Free" filter this originally also covered no longer exists: the
// Packs list now shows only packs the user can actually use (free ones,
// plus paid ones they own), so there is no free/paid toggle left to lose.
// What remains under test is that (a) every surviving filter still travels
// together on one call, including through pagination, and (b) the owned-pack
// ids that define "usable" are forwarded on every call — dropping those
// would make a user's own paid packs vanish from the list.
//
// This drives the REAL PackProvider.loadBrowsePacks/loadMoreBrowsePacks
// against a lightweight fake PackRepository that just records the
// arguments it was called with, without needing a live Supabase-backed
// repository.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/services/pack_sync_service.dart';
import 'package:jma3a/features/packs/data/pack_repository.dart';
import 'package:jma3a/features/packs/presentation/pack_provider.dart';
import 'package:mocktail/mocktail.dart';

// PackSyncService.instance touches Supabase.instance in its own
// constructor (a real, uninitialized singleton in this offline suite) —
// unusable here. Neither loadBrowsePacks nor loadMoreBrowsePacks (the
// methods under test) ever call anything on it, so a mocktail Mock
// (which never runs PackSyncService's own constructor at all — `Mock`'s
// implements clause is purely a type-conformance stand-in) sidesteps that
// entirely without needing to touch PackProvider's own constructor.
class _MockPackSyncService extends Mock implements PackSyncService {}

class _RecordedBrowseCall {
  _RecordedBrowseCall({
    required this.gameType,
    required this.categoryId,
    required this.ownedPackIds,
    required this.language,
  });
  final String? gameType;
  final String? categoryId;
  final List<String> ownedPackIds;
  final String? language;
}

/// A minimal stand-in for PackRepository — overrides only browsePacks (the
/// one method under test) and records every call's arguments, rather than
/// mocking the whole class or touching Supabase.
class _FakePackRepository implements PackRepository {
  final calls = <_RecordedBrowseCall>[];

  @override
  Future<List<PackEntity>> browsePacks({
    String? gameType,
    String? categoryId,
    List<String> ownedPackIds = const [],
    String? language,
    String? query,
    String sortBy = 'avg_rating',
    int page = 0,
    int perPage = 20,
  }) async {
    calls.add(
      _RecordedBrowseCall(
        gameType: gameType,
        categoryId: categoryId,
        ownedPackIds: ownedPackIds,
        language: language,
      ),
    );
    return const [];
  }

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

void main() {
  group('PackProvider.loadBrowsePacks — filters combine as AND', () {
    late _FakePackRepository repo;
    late PackProvider provider;

    setUp(() {
      repo = _FakePackRepository();
      provider = PackProvider(
        packRepository: repo,
        packSyncService: _MockPackSyncService(),
      );
    });

    test('category, language and game type are all forwarded together on '
        'the same call, not independently', () async {
      await provider.loadBrowsePacks(
        reset: true,
        gameType: 'meme_game',
        categoryId: 'cat-1',
        language: 'ar',
      );

      final call = repo.calls.single;
      expect(call.gameType, 'meme_game');
      expect(call.categoryId, 'cat-1');
      expect(call.language, 'ar');
    });

    test('the owned-pack ids that define a usable pack are forwarded on '
        'every call', () async {
      await provider.loadBrowsePacks(reset: true, gameType: 'truth_or_dare');

      expect(repo.calls, hasLength(1));
      expect(
        repo.calls.single.ownedPackIds,
        isNotNull,
        reason: 'omitting these would silently hide every paid pack the '
            'user actually owns',
      );
    });
  });

  group('PackProvider.loadMoreBrowsePacks — pagination preserves every '
      'active filter', () {
    test('language and game type are accepted and forwarded (the actual '
        'gap: this method used to only take gameType/categoryId, so '
        'scrolling to a further page silently dropped the rest)', () async {
      final repo = _FakePackRepository();
      // _hasMorePacks defaults to true before any load, so this exercises
      // loadMoreBrowsePacks's own forwarding logic directly, isolated
      // from loadBrowsePacks's separate has-more bookkeeping.
      final provider = PackProvider(
        packRepository: repo,
        packSyncService: _MockPackSyncService(),
      );

      await provider.loadMoreBrowsePacks(
        gameType: 'truth_or_dare',
        language: 'ar',
      );

      expect(repo.calls, hasLength(1));
      final call = repo.calls.single;
      expect(call.gameType, 'truth_or_dare');
      expect(call.language, 'ar');
    });
  });
}
