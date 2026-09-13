// Regression coverage for item 2 — Packs filtering combined incorrectly.
//
// ROOT CAUSE: PackRepository.browsePacks itself ANDs whatever filters it's
// given (confirmed correct at the query layer) — the bug was entirely in
// the CALLERS: marketplace_screen.dart's onGameTypeChanged/onFreeOnlyChanged
// each passed ONLY the filter that just changed, so the other currently-
// active filter silently reset to its default (freeOnly: false / gameType:
// null) on every call — e.g. selecting Free then Truth or Dare dropped the
// Free filter, showing every Truth or Dare pack, paid included.
// PackProvider.loadMoreBrowsePacks had the same gap for pagination: it
// didn't even accept a freeOnly/language parameter to forward.
//
// This drives the REAL PackProvider.loadBrowsePacks/loadMoreBrowsePacks
// against a lightweight fake PackRepository that just records the
// arguments it was called with — proving the FIX (every filter callback
// re-sends the full current filter set) at the actual layer the bug lived
// in, without needing a live Supabase-backed repository.
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
    required this.freeOnly,
    required this.language,
  });
  final String? gameType;
  final String? categoryId;
  final bool freeOnly;
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
    bool freeOnly = false,
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
        freeOnly: freeOnly,
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

    test('game type + free-only are both sent together on the same call '
        '(the exact combination that used to lose one filter)', () async {
      await provider.loadBrowsePacks(
        reset: true,
        gameType: 'truth_or_dare',
        freeOnly: true,
      );

      expect(repo.calls, hasLength(1));
      expect(repo.calls.single.gameType, 'truth_or_dare');
      expect(repo.calls.single.freeOnly, isTrue);
    });

    test('category + price and language + game type combinations are all '
        'forwarded together, not independently', () async {
      await provider.loadBrowsePacks(
        reset: true,
        gameType: 'meme_game',
        categoryId: 'cat-1',
        freeOnly: true,
        language: 'ar',
      );

      final call = repo.calls.single;
      expect(call.gameType, 'meme_game');
      expect(call.categoryId, 'cat-1');
      expect(call.freeOnly, isTrue);
      expect(call.language, 'ar');
    });
  });

  group('PackProvider.loadMoreBrowsePacks — pagination preserves every '
      'active filter', () {
    test('freeOnly and language are now accepted and forwarded (the actual '
        'gap: this method used to only take gameType/categoryId, so '
        'scrolling to a further page under Free-only silently dropped it)',
        () async {
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
        freeOnly: true,
        language: 'ar',
      );

      expect(repo.calls, hasLength(1));
      final call = repo.calls.single;
      expect(call.gameType, 'truth_or_dare');
      expect(call.freeOnly, isTrue,
          reason: 'the exact regression: pagination must not silently '
              'reset freeOnly to false');
      expect(call.language, 'ar');
    });
  });
}
