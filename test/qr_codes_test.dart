// Item 7 (QR codes) — regression coverage for:
//
// - canRevealRoomQr: the admin/other-player reveal permission gate
//   (qr_reveal_sheets.dart). Purely a UI-affordance decision — the real
//   authorization is RoomRepository.joinByCode/joinRoom, unaffected by
//   this function either way (see its own doc comment).
// - parseInviteLink (deep_links.dart): the exact parser both native deep
//   links AND the QR scanner (via resolveScannedQrRoute) share — made
//   public from DeepLinkService's former private _parseInvite in this
//   pass specifically so the scanner could reuse it instead of
//   duplicating the URL-matching logic.
// - resolveScannedQrRoute (qr_scan_screen.dart): turns a raw scanned
//   string into the in-app route to navigate to, reusing
//   parseInviteLink/parseUsernameProfileLink/parseProfileLink — never a
//   direct join/navigation action of its own, so the resulting route
//   always goes through the SAME existing screens (JoinInviteScreen,
//   UsernameProfileResolverScreen, the legacy /user/:id route) and their
//   existing authorization, not a QR-specific shortcut.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/deep_links.dart';
import 'package:jma3a/features/rooms/presentation/screens/qr_scan_screen.dart';
import 'package:jma3a/shared/widgets/qr/qr_reveal_sheets.dart';

void main() {
  group('canRevealRoomQr — item 7', () {
    test('the owner/admin can always reveal, regardless of room state', () {
      expect(
        canRevealRoomQr(
          isOwner: true,
          isPrivate: true,
          isClosed: true,
          isFull: true,
        ),
        isTrue,
      );
    });

    test('a non-admin player can reveal when the room is public, open, '
        'and not full', () {
      expect(
        canRevealRoomQr(
          isOwner: false,
          isPrivate: false,
          isClosed: false,
          isFull: false,
        ),
        isTrue,
      );
    });

    test('a non-admin player cannot reveal a private room\'s QR', () {
      expect(
        canRevealRoomQr(
          isOwner: false,
          isPrivate: true,
          isClosed: false,
          isFull: false,
        ),
        isFalse,
      );
    });

    test('a non-admin player cannot reveal a closed room\'s QR', () {
      expect(
        canRevealRoomQr(
          isOwner: false,
          isPrivate: false,
          isClosed: true,
          isFull: false,
        ),
        isFalse,
      );
    });

    test('a non-admin player cannot reveal a full room\'s QR', () {
      expect(
        canRevealRoomQr(
          isOwner: false,
          isPrivate: false,
          isClosed: false,
          isFull: true,
        ),
        isFalse,
      );
    });
  });

  group('parseInviteLink — item 7 (shared with native deep links)', () {
    test('parses the jma3a:// custom-scheme QR form (code only, no '
        'invited_by — a room QR never carries a personal invite)', () {
      final payload = parseInviteLink(Uri.parse('jma3a://join?code=ABC123'));
      expect(payload?.code, 'ABC123');
      expect(payload?.invitedBy, isNull);
    });

    test('parses the HTTPS App Link form with invited_by', () {
      final payload = parseInviteLink(
        Uri.parse('https://jma3a.com/join?code=ABC123&invited_by=user-1'),
      );
      expect(payload?.code, 'ABC123');
      expect(payload?.invitedBy, 'user-1');
    });

    test('rejects a link with no code', () {
      expect(parseInviteLink(Uri.parse('jma3a://join')), isNull);
    });

    test('a profile link is never mistaken for an invite link', () {
      expect(parseInviteLink(Uri.parse('jma3a://u/someuser')), isNull);
    });
  });

  group('resolveScannedQrRoute — item 7', () {
    test('a room-invite QR resolves to the /join route, reusing '
        'JoinInviteScreen\'s own joinByCode validation — never a direct '
        'join', () {
      expect(
        resolveScannedQrRoute('jma3a://join?code=ABC123'),
        '/join?code=ABC123',
      );
    });

    test('an invite QR carrying invited_by preserves it in the resolved '
        'route', () {
      expect(
        resolveScannedQrRoute(
          'https://jma3a.com/join?code=ABC123&invited_by=user-1',
        ),
        '/join?code=ABC123&invited_by=user-1',
      );
    });

    test('a profile QR (username form) resolves to /u/<username>', () {
      expect(resolveScannedQrRoute('jma3a://u/alex'), '/u/alex');
    });

    test('a legacy profile QR (uuid form) resolves to /user/<id>', () {
      expect(
        resolveScannedQrRoute('jma3a://profile/user-123'),
        '/user/user-123',
      );
    });

    test('an unrecognized/garbage scan resolves to null — never a '
        'guessed destination', () {
      expect(resolveScannedQrRoute('not a url at all'), isNull);
      expect(resolveScannedQrRoute('https://example.com/nope'), isNull);
      expect(resolveScannedQrRoute(''), isNull);
    });
  });
}
