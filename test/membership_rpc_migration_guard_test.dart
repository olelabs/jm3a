// Phase 1C-B-2 guard — the Flutter client changes room membership only
// through the six B-1 RPCs, never by writing public.room_members directly.
// Source scan (comment lines stripped: room_repository.dart keeps large
// commented-out blocks of the old code).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// [path]'s source with every `//` comment line blanked (line count kept).
String _live(String path) => File(path)
    .readAsLinesSync()
    .map((l) => l.trimLeft().startsWith('//') ? '' : l)
    .join('\n');

List<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

/// The body of the first method whose declaration matches [signature].
String _methodBody(String source, String signature) {
  final start = source.indexOf(signature);
  expect(start, isNot(-1), reason: 'method not found: $signature');
  final open = source.indexOf('{', start);
  var depth = 0;
  for (var i = open; i < source.length; i++) {
    if (source[i] == '{') depth++;
    if (source[i] == '}' && --depth == 0) return source.substring(open, i + 1);
  }
  fail('unbalanced braces after $signature');
}

const _repoPath = 'lib/features/rooms/data/room_repository.dart';
const _providerPath = 'lib/features/rooms/presentation/room_provider.dart';

/// Each B-1 RPC and its expected number of call sites. member_leave_room is
/// used twice by design: RoomRepository.leaveRoom and the member part of
/// RoomRepository.forceLeaveRoom (both soft leaves of the caller's own row).
const _b1RpcCallSites = {
  'member_join_room': 1,
  'member_leave_room': 2,
  'member_set_ready': 1,
  'member_set_away': 1,
  'member_leave_room_definitively': 1,
  'member_evict_stale': 1,
};

final _b1Rpcs = _b1RpcCallSites.keys.toList();

void main() {
  group('no direct room_members writes anywhere in lib/', () {
    final readOrStream = RegExp(
      r"from\(\s*'room_members'\s*\)\s*\.(select|stream)\(",
    );

    test('every live .from(\'room_members\') is followed by a read', () {
      for (final file in _dartFiles('lib')) {
        final src = _live(file.path);
        final froms = RegExp(r"\.from\(\s*'room_members'\s*\)").allMatches(src);
        final reads = readOrStream.allMatches(src);
        expect(reads.length, froms.length,
            reason: '${file.path}: a room_members query that is not a read');
      }
    });

    test('no insert/upsert/update/delete chained after room_members', () {
      final write = RegExp(r'\.(insert|upsert|update|delete)\(');
      for (final file in _dartFiles('lib')) {
        final src = _live(file.path);
        // Each room_members query chain, up to its terminating ';'.
        for (final m in RegExp(r"\.from\(\s*'room_members'\s*\)").allMatches(src)) {
          final end = src.indexOf(';', m.end);
          final chain = src.substring(m.start, end == -1 ? src.length : end);
          expect(write.hasMatch(chain), isFalse,
              reason: '${file.path}: direct room_members write: $chain');
        }
      }
    });

    test('no membership column is written by key anywhere in lib/', () {
      final columnWrite = RegExp(
        r"'(left_at|is_ready|is_away|left_definitively|is_hidden_spectator)'\s*:",
      );
      for (final file in _dartFiles('lib')) {
        expect(columnWrite.hasMatch(_live(file.path)), isFalse,
            reason: '${file.path} writes a room_members column by key');
      }
    });
  });

  group('the six B-1 RPCs', () {
    test('each has its expected call sites, in RoomRepository only', () {
      for (final rpc in _b1Rpcs) {
        final literal = RegExp("'$rpc'");
        var total = 0;
        for (final file in _dartFiles('lib')) {
          final n = literal.allMatches(_live(file.path)).length;
          if (n > 0) {
            expect(file.path, _repoPath, reason: '$rpc called outside the repository');
          }
          total += n;
        }
        expect(total, _b1RpcCallSites[rpc], reason: '$rpc call sites');
      }
    });

    test('every membership RPC goes through _membershipRpc (exact mapper)', () {
      final src = _live(_repoPath);
      for (final rpc in _b1Rpcs) {
        expect(
          RegExp("_membershipRpc\\(\\s*'$rpc'").hasMatch(src),
          isTrue,
          reason: rpc,
        );
      }
    });

    test('no substring matching of approval codes anywhere in lib/', () {
      for (final file in _dartFiles('lib')) {
        expect(
          _live(file.path).contains(RegExp(r"contains\(\s*'(\w+_)?approval_required'")),
          isFalse,
          reason: file.path,
        );
      }
    });
  });

  group('room provider lifecycle', () {
    final provider = _live(_providerPath);

    test('_removeMember is local-only (no repository write)', () {
      final body = _methodBody(provider, 'void _removeMember(String userId)');
      expect(body.contains('_repo.'), isFalse);
      expect(body.contains('_supabase'), isFalse);
    });

    test('only the grace-timeout path evicts, via evictStaleMember', () {
      final calls = RegExp(r'\.evictStaleMember\(').allMatches(provider).length;
      expect(calls, 1);
      final body = _methodBody(
        provider,
        'Future<void> _confirmAndRemoveMember(String userId)',
      );
      expect(body.contains('_repo.evictStaleMember('), isTrue);
    });

    test('setReady writes through the repository, not room_members', () {
      final body = _methodBody(provider, 'Future<void> setReady(bool ready)');
      expect(body.contains('_repo.setMemberReady('), isTrue);
      expect(body.contains('room_members'), isFalse);
    });

    test('leaveRoom can only leave the caller\'s own membership', () {
      expect(
        _live(_repoPath).contains('Future<void> leaveRoom({required String roomId})'),
        isTrue,
      );
    });
  });
}
