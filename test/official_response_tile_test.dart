// Item 3 (Official Responses) — layout regression coverage for the real
// production OfficialResponseTile widget (mirrors
// friends_narrow_width_layout_test.dart's established pattern: render the
// actual widget, not a reconstructed approximation, at narrow widths/RTL/
// large text with the real AppTheme) plus pure-logic coverage for
// officialResponseCategoryFor's bucketing (the "unrelated notifications
// never appear here" and "read/unread" requirements — privacy/RLS itself
// is proven at the DB layer in the migration's own dry-run tests, not
// here, since this widget only ever renders what it's given).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/features/notifications/domain/notification_entity.dart';
import 'package:jma3a/features/notifications/domain/official_response_category.dart';
import 'package:jma3a/shared/widgets/cards/official_response_tile.dart';

NotificationEntity _notification({
  String id = 'n1',
  NotificationType type = NotificationType.moderation,
  Map<String, dynamic> data = const {},
  Map<String, dynamic>? titleJson,
  Map<String, dynamic>? bodyJson,
  bool isRead = false,
  DateTime? expiresAt,
}) => NotificationEntity(
  id: id,
  userId: 'u1',
  type: type,
  titleJson: titleJson ?? const {'en': 'Title'},
  bodyJson: bodyJson ?? const {'en': 'Body'},
  data: data,
  isRead: isRead,
  createdAt: DateTime(2026, 1, 1),
  expiresAt: expiresAt,
);

Widget _wrapInList(
  List<Widget> items, {
  double width = 390,
  double textScale = 1.0,
  TextDirection direction = TextDirection.ltr,
}) => MediaQuery(
  data: MediaQueryData(
    size: Size(width, 800),
    textScaler: TextScaler.linear(textScale),
  ),
  child: Directionality(
    textDirection: direction,
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: direction == TextDirection.rtl ? const Locale('ar') : null,
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: ListView(padding: const EdgeInsets.all(16), children: items),
        ),
      ),
    ),
  ),
);

void main() {
  group('officialResponseCategoryFor — bucketing', () {
    test('pack review types map to reviews', () {
      expect(
        officialResponseCategoryFor(_notification(type: NotificationType.packApproved)),
        OfficialResponseCategory.reviews,
      );
      expect(
        officialResponseCategoryFor(_notification(type: NotificationType.packRejected)),
        OfficialResponseCategory.reviews,
      );
    });

    test('moderation with category=suspension maps to bansAndSuspensions', () {
      expect(
        officialResponseCategoryFor(_notification(data: const {'category': 'suspension'})),
        OfficialResponseCategory.bansAndSuspensions,
      );
    });

    test('moderation with category=warning maps to warnings', () {
      expect(
        officialResponseCategoryFor(_notification(data: const {'category': 'warning'})),
        OfficialResponseCategory.warnings,
      );
    });

    test('moderation with category=creator_verification_review maps to requestsAndDecisions', () {
      expect(
        officialResponseCategoryFor(
          _notification(data: const {'category': 'creator_verification_review'}),
        ),
        OfficialResponseCategory.requestsAndDecisions,
      );
    });

    test('moderation with category=report_response maps to requestsAndDecisions', () {
      expect(
        officialResponseCategoryFor(_notification(data: const {'category': 'report_response'})),
        OfficialResponseCategory.requestsAndDecisions,
      );
    });

    test('unrelated notification types (chat, follow, wallet, streak) are excluded entirely', () {
      for (final type in [
        NotificationType.chatMessage,
        NotificationType.follow,
        NotificationType.walletCredit,
        NotificationType.streakIncreased,
        NotificationType.roomInvite,
      ]) {
        expect(officialResponseCategoryFor(_notification(type: type)), isNull);
        expect(isOfficialResponseNotification(_notification(type: type)), isFalse);
      }
    });
  });

  group('OfficialResponseTile — real production widget, narrow widths', () {
    for (final width in [320.0, 360.0, 390.0]) {
      testWidgets('renders without exception at ${width}px (unread, with expiry)', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrapInList([
            OfficialResponseTile(
              notification: _notification(
                data: const {'category': 'suspension'},
                titleJson: const {'en': 'Your account has been suspended'},
                bodyJson: const {
                  'en':
                      'This is a fairly long reason string that should still '
                      'wrap and never overflow even at the narrowest supported width.',
                },
                expiresAt: DateTime(2026, 2, 1),
              ),
              languageCode: 'en',
            ),
          ], width: width),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders without exception at ${width}px (read, no expiry)', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrapInList([
            OfficialResponseTile(
              notification: _notification(isRead: true),
              languageCode: 'en',
            ),
          ], width: width),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('renders without exception in RTL (Arabic)', (tester) async {
      await tester.pumpWidget(
        _wrapInList([
          OfficialResponseTile(
            notification: _notification(
              titleJson: const {'ar': 'تم تعليق حسابك لفترة طويلة جدًا من الوقت'},
              bodyJson: const {'ar': 'هذا سبب طويل جدًا يجب أن يلتف بشكل صحيح في اتجاه اليمين إلى اليسار'},
            ),
            languageCode: 'ar',
          ),
        ], width: 360, direction: TextDirection.rtl),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without exception at 1.8x text scale', (tester) async {
      await tester.pumpWidget(
        _wrapInList([
          OfficialResponseTile(notification: _notification(), languageCode: 'en'),
        ], width: 360, textScale: 1.8),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping the tile invokes onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrapInList([
          OfficialResponseTile(
            notification: _notification(),
            languageCode: 'en',
            onTap: () => tapped = true,
          ),
        ]),
      );
      await tester.pump();
      await tester.tap(find.byType(OfficialResponseTile));
      expect(tapped, isTrue);
    });
  });
}
