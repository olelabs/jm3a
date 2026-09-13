import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/constants/app_constants.dart';
import 'package:jma3a/deep_links.dart';

const _uuidPattern =
    r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}';

/// Profile sharing correction pass — deep link parsing.
void main() {
  group('parseProfileLink', () {
    test('parses the HTTPS App Link form', () {
      final payload = parseProfileLink(
        Uri.parse('https://jma3a.com/profile/user-123'),
      );
      expect(payload?.userId, 'user-123');
    });

    test('parses the jma3a:// custom scheme form', () {
      final payload = parseProfileLink(Uri.parse('jma3a://profile/user-123'));
      expect(payload?.userId, 'user-123');
    });

    test('a real UUID-shaped id round-trips correctly', () {
      const id = '4a8080df-bd31-45df-ae1d-a88eede8f602';
      final payload = parseProfileLink(
        Uri.parse('https://jma3a.com/profile/$id'),
      );
      expect(payload?.userId, id);
    });

    test('a room-invite link is never mistaken for a profile link', () {
      expect(
        parseProfileLink(Uri.parse('https://jma3a.com/join?code=ABC123')),
        isNull,
      );
      expect(parseProfileLink(Uri.parse('jma3a://join?code=ABC123')), isNull);
    });

    test(
      'a link with no id segment is rejected, not treated as an empty id',
      () {
        expect(
          parseProfileLink(Uri.parse('https://jma3a.com/profile/')),
          isNull,
        );
        expect(parseProfileLink(Uri.parse('jma3a://profile/')), isNull);
      },
    );

    test(
      'a link with extra path segments is rejected (only /profile/<id> is valid, not /profile/<id>/extra)',
      () {
        expect(
          parseProfileLink(
            Uri.parse('https://jma3a.com/profile/user-123/extra'),
          ),
          isNull,
        );
      },
    );

    test('an unrelated host or scheme is never treated as a profile link', () {
      expect(
        parseProfileLink(Uri.parse('https://evil.example/profile/user-123')),
        isNull,
      );
      expect(
        parseProfileLink(Uri.parse('ftp://jma3a.com/profile/user-123')),
        isNull,
      );
    });
  });

  group('AppConstants.publicProfileUrl — the ONLY link shareProfile() actually '
      'shares (HTTPS, tappable in WhatsApp/SMS/etc. — see profile_share.dart\'s '
      "history of sharing appProfileLink instead, which wasn't)", () {
    test(
      'builds the expected HTTPS link on the dedicated profile host, username-keyed',
      () {
        final url = AppConstants.publicProfileUrl('ahmed_99');
        expect(url, 'https://www.moujgroup.jma3a.com/u/ahmed_99');
      },
    );

    test('uses AppConstants.profileWebHost, not inviteWebHost', () {
      expect(AppConstants.profileWebHost, 'www.moujgroup.jma3a.com');
      expect(AppConstants.profileWebHost, isNot(AppConstants.inviteWebHost));
      expect(
        AppConstants.publicProfileUrl('ahmed_99'),
        contains(AppConstants.profileWebHost),
      );
    });

    test('never contains a UUID-shaped internal user id', () {
      final url = AppConstants.publicProfileUrl('ahmed_99');
      expect(RegExp(_uuidPattern).hasMatch(url), isFalse);
    });

    test('is a real https:// link, never the jma3a:// custom scheme', () {
      final url = AppConstants.publicProfileUrl('ahmed_99');
      expect(url, startsWith('https://'));
    });

    test('round-trips through parseUsernameProfileLink', () {
      final url = AppConstants.publicProfileUrl('sara_the_great');
      expect(parseUsernameProfileLink(Uri.parse(url)), 'sara_the_great');
    });
  });

  group(
    'AppConstants.appProfileLink — a working internal-routing form, but NOT '
    'what shareProfile() shares externally',
    () {
      test('builds the app deep link (jma3a://u/<username>), never HTTPS', () {
        final url = AppConstants.appProfileLink('ahmed_99');
        expect(url, 'jma3a://u/ahmed_99');
        expect(url, isNot(startsWith('https://')));
      });

      test('never contains a UUID-shaped internal user id', () {
        final url = AppConstants.appProfileLink('ahmed_99');
        expect(RegExp(_uuidPattern).hasMatch(url), isFalse);
      });

      test('uses the username exactly as given, not the internal id', () {
        final url = AppConstants.appProfileLink('sara_the_great');
        expect(url, contains('/u/sara_the_great'));
        expect(url, isNot(contains('user-')));
      });

      test('round-trips through parseUsernameProfileLink', () {
        final url = AppConstants.appProfileLink('sara_the_great');
        expect(parseUsernameProfileLink(Uri.parse(url)), 'sara_the_great');
      });
    },
  );

  group('parseUsernameProfileLink', () {
    test('parses the jma3a:// custom scheme form', () {
      expect(
        parseUsernameProfileLink(Uri.parse('jma3a://u/ahmed_99')),
        'ahmed_99',
      );
    });

    test('parses the CURRENT HTTPS profile host (www.moujgroup.jma3a.com)', () {
      expect(
        parseUsernameProfileLink(
          Uri.parse('https://www.moujgroup.jma3a.com/u/ahmed_99'),
        ),
        'ahmed_99',
      );
    });

    test('still parses the LEGACY HTTPS host (jma3a.com) so a link shared '
        'before the domain switch keeps working', () {
      expect(
        parseUsernameProfileLink(Uri.parse('https://jma3a.com/u/ahmed_99')),
        'ahmed_99',
      );
    });

    test('a room-invite or legacy uuid-profile link is never mistaken for '
        'a username link', () {
      expect(
        parseUsernameProfileLink(Uri.parse('jma3a://join?code=ABC123')),
        isNull,
      );
      expect(
        parseUsernameProfileLink(Uri.parse('jma3a://profile/user-123')),
        isNull,
      );
      expect(
        parseUsernameProfileLink(
          Uri.parse('https://jma3a.com/profile/user-123'),
        ),
        isNull,
      );
    });

    test('a link with no username segment is rejected, not treated as an '
        'empty username', () {
      expect(parseUsernameProfileLink(Uri.parse('jma3a://u/')), isNull);
      expect(
        parseUsernameProfileLink(
          Uri.parse('https://www.moujgroup.jma3a.com/u/'),
        ),
        isNull,
      );
    });

    test('a link with extra path segments is rejected', () {
      expect(
        parseUsernameProfileLink(Uri.parse('jma3a://u/ahmed_99/extra')),
        isNull,
      );
    });

    test('an unrelated host or scheme is never treated as a username link', () {
      expect(
        parseUsernameProfileLink(Uri.parse('https://evil.example/u/ahmed_99')),
        isNull,
      );
      expect(
        parseUsernameProfileLink(
          Uri.parse('ftp://www.moujgroup.jma3a.com/u/ahmed_99'),
        ),
        isNull,
      );
    });
  });
}
