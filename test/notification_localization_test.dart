// Tests for the notification localization fix: the notifications screen
// was hardcoding NotificationEntity.titleFor('en')/bodyFor('en') regardless
// of the app's selected language (notifications_screen.dart's
// NotificationTile) — the in-app toast overlay already read the real
// current locale correctly, so the bug was isolated to that one call site.
// This suite exercises the pure model-layer logic the fix depends on:
// localizedValue's fallback chain, parseLocalizedJson's tolerance of both
// the JSONB-object and legacy-plain-string DB shapes, and
// NotificationEntity/InAppToast's titleFor/bodyFor built on top of them —
// all fully offline-testable, no Supabase mock seam needed for any of it,
// since none of this depends on network/DB state.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/notifications/domain/notification_entity.dart';

NotificationEntity _entity({
  required Map<String, dynamic> title,
  required Map<String, dynamic> body,
  NotificationType type = NotificationType.system,
}) => NotificationEntity(
  id: 'n1',
  userId: 'u1',
  type: type,
  titleJson: title,
  bodyJson: body,
  data: const {},
  isRead: false,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  group('localizedValue — language resolution', () {
    const json = {'en': 'Hello', 'ar': 'مرحبا', 'fr': 'Bonjour'};

    test('English user sees the English value', () {
      expect(localizedValue(json, 'en'), 'Hello');
    });

    test('Arabic user sees the Arabic value', () {
      expect(localizedValue(json, 'ar'), 'مرحبا');
    });

    test('French user sees the French value', () {
      expect(localizedValue(json, 'fr'), 'Bonjour');
    });

    test('missing requested locale falls back to English', () {
      expect(localizedValue(json, 'de'), 'Hello');
    });

    test('same map, called with different lang args, returns different '
        'text — proves a language switch re-renders an already-loaded '
        'notification without needing it recreated/refetched', () {
      expect(localizedValue(json, 'en'), isNot(localizedValue(json, 'ar')));
      expect(localizedValue(json, 'ar'), isNot(localizedValue(json, 'fr')));
    });

    test('when English is unavailable, falls back to another available '
        'value rather than rendering empty', () {
      const noEnglish = {'ar': 'مرحبا', 'fr': 'Bonjour'};
      final result = localizedValue(noEnglish, 'de');
      expect(result, isNotEmpty);
      expect(['مرحبا', 'Bonjour'], contains(result));
    });

    test('a genuinely empty map yields empty string, not a crash', () {
      expect(localizedValue(const {}, 'en'), '');
    });

    test('an empty-string value for the requested language is skipped in '
        'favor of a real fallback, not returned as-is', () {
      const partiallyEmpty = {'ar': '', 'en': 'Hello'};
      expect(localizedValue(partiallyEmpty, 'ar'), 'Hello');
    });
  });

  group('parseLocalizedJson — DB shape tolerance', () {
    test('a real JSONB object decodes straight through', () {
      final parsed = parseLocalizedJson({'en': 'Hi', 'ar': 'أهلا'});
      expect(parsed, {'en': 'Hi', 'ar': 'أهلا'});
    });

    test('a legacy plain-string value (old pre-localization write path) is '
        'wrapped, not thrown away or crashed on', () {
      final parsed = parseLocalizedJson('Plain English text');
      expect(parsed, isNotEmpty);
      expect(localizedValue(parsed, 'ar'), 'Plain English text');
      expect(localizedValue(parsed, 'en'), 'Plain English text');
    });

    test('null decodes to an empty map, not a crash', () {
      expect(parseLocalizedJson(null), <String, dynamic>{});
    });

    test('an empty string decodes to an empty map', () {
      expect(parseLocalizedJson(''), <String, dynamic>{});
    });
  });

  group('NotificationEntity.titleFor/bodyFor', () {
    test('plain-string title/body (legacy format) renders identically '
        'regardless of requested language, never blank', () {
      final n = _entity(
        title: parseLocalizedJson('Old Notification'),
        body: parseLocalizedJson('Old body text'),
      );
      expect(n.titleFor('en'), 'Old Notification');
      expect(n.titleFor('ar'), 'Old Notification');
      expect(n.titleFor('fr'), 'Old Notification');
      expect(n.bodyFor('ar'), 'Old body text');
    });

    test('localized JSONB title/body renders per-language', () {
      final n = _entity(
        title: const {
          'en': 'New Friend Request',
          'ar': 'طلب صداقة جديد',
          'fr': "Nouvelle demande d'ami",
        },
        body: const {
          'en': 'Alex sent you a friend request.',
          'ar': 'أرسل أليكس إليك طلب صداقة.',
          'fr': "Alex vous a envoyé une demande d'ami.",
        },
      );
      expect(n.titleFor('en'), 'New Friend Request');
      expect(n.titleFor('ar'), 'طلب صداقة جديد');
      expect(n.titleFor('fr'), "Nouvelle demande d'ami");
      expect(n.bodyFor('en'), 'Alex sent you a friend request.');
      expect(n.bodyFor('ar'), 'أرسل أليكس إليك طلب صداقة.');
      expect(n.bodyFor('fr'), "Alex vous a envoyé une demande d'ami.");
    });

    test('streak_increased notification (stored as localized JSONB by the '
        'on_game_session_completed DB trigger) resolves per-language and '
        'round-trips through NotificationType.fromString correctly', () {
      final n = _entity(
        type: NotificationType.fromString('streak_increased'),
        title: const {
          'en': '🔥 Streak Day 5!',
          'ar': '🔥 سلسلة اليوم 5!',
          'fr': '🔥 Série jour 5 !',
        },
        body: const {
          'en': 'You kept your streak going — 5 days in a row!',
          'ar': 'حافظت على سلسلتك — 5 أيام متتالية!',
          'fr': 'Vous avez maintenu votre série — 5 jours d\'affilée !',
        },
      );
      expect(n.type, NotificationType.streakIncreased);
      expect(n.type.dbString, 'streak_increased');
      expect(n.titleFor('en'), '🔥 Streak Day 5!');
      expect(n.titleFor('ar'), '🔥 سلسلة اليوم 5!');
      expect(n.titleFor('fr'), '🔥 Série jour 5 !');
      expect(n.bodyFor('fr'), 'Vous avez maintenu votre série — 5 jours d\'affilée !');
    });

    test('a notification missing the requested locale (e.g. only en/ar '
        'seeded) falls back to English for a French user', () {
      final n = _entity(
        title: const {'en': 'Room Invite', 'ar': 'دعوة لغرفة'},
        body: const {'en': 'You were invited.', 'ar': 'تمت دعوتك.'},
      );
      expect(n.titleFor('fr'), 'Room Invite');
      expect(n.bodyFor('fr'), 'You were invited.');
    });
  });

  group('InAppToast.titleFor/bodyFor — same fallback behavior as the list', () {
    test('localized JSONB resolves per-language', () {
      final toast = InAppToast(
        id: 't1',
        type: NotificationType.streakIncreased,
        titleJson: const {'en': 'Streak!', 'ar': 'سلسلة!', 'fr': 'Série !'},
        bodyJson: const {'en': 'Nice.', 'ar': 'رائع.', 'fr': 'Bien joué.'},
        data: const {},
        createdAt: DateTime(2026, 1, 1),
      );
      expect(toast.titleFor('ar'), 'سلسلة!');
      expect(toast.bodyFor('fr'), 'Bien joué.');
      expect(toast.titleFor('de'), 'Streak!'); // English fallback
    });
  });
}
