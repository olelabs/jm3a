import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/constants/app_constants.dart';
import 'package:jma3a/deep_links.dart';

/// Profile sharing correction pass — deep link parsing.
void main() {
  group('parseProfileLink', () {
    test('parses the HTTPS App Link form', () {
      final payload = parseProfileLink(Uri.parse('https://jma3a.com/profile/user-123'));
      expect(payload?.userId, 'user-123');
    });

    test('parses the jma3a:// custom scheme form', () {
      final payload = parseProfileLink(Uri.parse('jma3a://profile/user-123'));
      expect(payload?.userId, 'user-123');
    });

    test('a real UUID-shaped id round-trips correctly', () {
      const id = '4a8080df-bd31-45df-ae1d-a88eede8f602';
      final payload = parseProfileLink(Uri.parse('https://jma3a.com/profile/$id'));
      expect(payload?.userId, id);
    });

    test('a room-invite link is never mistaken for a profile link', () {
      expect(parseProfileLink(Uri.parse('https://jma3a.com/join?code=ABC123')), isNull);
      expect(parseProfileLink(Uri.parse('jma3a://join?code=ABC123')), isNull);
    });

    test('a link with no id segment is rejected, not treated as an empty id', () {
      expect(parseProfileLink(Uri.parse('https://jma3a.com/profile/')), isNull);
      expect(parseProfileLink(Uri.parse('jma3a://profile/')), isNull);
    });

    test('a link with extra path segments is rejected (only /profile/<id> is valid, not /profile/<id>/extra)', () {
      expect(parseProfileLink(Uri.parse('https://jma3a.com/profile/user-123/extra')), isNull);
    });

    test('an unrelated host or scheme is never treated as a profile link', () {
      expect(parseProfileLink(Uri.parse('https://evil.example/profile/user-123')), isNull);
      expect(parseProfileLink(Uri.parse('ftp://jma3a.com/profile/user-123')), isNull);
    });
  });

  group('AppConstants.profileShareUrl', () {
    test('builds the expected HTTPS link, never the custom scheme (renders as plain text in chat apps)', () {
      final url = AppConstants.profileShareUrl('user-123');
      expect(url, 'https://jma3a.com/profile/user-123');
      expect(url, isNot(startsWith('jma3a://')));
    });

    test('round-trips through parseProfileLink', () {
      final url = AppConstants.profileShareUrl('user-456');
      final payload = parseProfileLink(Uri.parse(url));
      expect(payload?.userId, 'user-456');
    });
  });
}
