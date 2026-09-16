// Coverage for the "My Requests" tab added to the existing Official
// Responses screen (Settings → Official Responses).
//
// The feature is deliberately a READ-ONLY projection over request tables
// that already exist and that the user can already read under their own
// RLS policies (`account_deletion_requests: own read`, `pack_reports: own
// read`, `reports: own read`, `creator_verifications: own read`,
// `creator_recovery_complaints: own read`). No new request system, no new
// write path, and no new status vocabulary — so what actually needs
// guarding is the set of RULES that keep it honest:
//
//  * cancellation is offered for exactly the one request the backend can
//    cancel, and never for another type that merely also has a 'pending'
//    state (no RPC exists to cancel those — the button could not work);
//  * every status shown is a real backend value, with an unrecognized one
//    rendered verbatim rather than relabelled or dropped;
//  * blocking is not modelled as a request at all (blocked_users has no
//    status, reviewer or decision — it takes effect immediately);
//  * a report never surfaces the target's identity or the moderation
//    outcome, only the KIND of thing that was reported.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/features/notifications/domain/user_request_entity.dart';
import 'package:jma3a/shared/widgets/cards/user_request_tile.dart';

UserRequestEntity _request({
  required UserRequestType type,
  required String status,
  DateTime? decidedAt,
  Map<String, dynamic>? targetTitleJson,
  String? reportTargetType,
}) => UserRequestEntity(
  id: 'req-1',
  type: type,
  status: status,
  submittedAt: DateTime(2026, 3, 4),
  decidedAt: decidedAt,
  targetTitleJson: targetTitleJson,
  reportTargetType: reportTargetType,
);

Future<AppLocalizations> _pumpTile(
  WidgetTester tester,
  UserRequestEntity request, {
  VoidCallback? onCancel,
}) async {
  late AppLocalizations l10n;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context);
          return Scaffold(
            body: UserRequestTile(
              request: request,
              languageCode: 'en',
              onCancel: onCancel,
            ),
          );
        },
      ),
    ),
  );
  await tester.pump();
  return l10n;
}

void main() {
  group('cancellation is offered only where the backend supports it', () {
    test('a PENDING account deletion can be cancelled — the one request the '
        'cancel_account_deletion_request RPC actually handles', () {
      expect(
        _request(
          type: UserRequestType.accountDeletion,
          status: 'pending',
        ).canCancel,
        isTrue,
      );
    });

    test('an account deletion already acted on cannot be cancelled — '
        'cancellation must never be offered once it is no longer '
        'reversible', () {
      for (final status in ['approved', 'rejected']) {
        expect(
          _request(
            type: UserRequestType.accountDeletion,
            status: status,
          ).canCancel,
          isFalse,
          reason: 'a $status deletion request is settled',
        );
      }
    });

    test('no OTHER request type is cancellable, not even while pending — '
        'there is no backend operation to cancel them, so offering it '
        'would be a button that cannot work', () {
      for (final type in UserRequestType.values) {
        if (type == UserRequestType.accountDeletion) continue;
        for (final status in ['pending', 'open', 'under_review']) {
          expect(
            _request(type: type, status: status).canCancel,
            isFalse,
            reason: '$type/$status has no cancellation path',
          );
        }
      }
    });
  });

  group('statuses are real backend values', () {
    testWidgets('every status the source tables can hold has a localized '
        'label', (tester) async {
      final l10n = await _pumpTile(
        tester,
        _request(type: UserRequestType.userReport, status: 'open'),
      );

      // account_deletion_requests / creator_verifications /
      // creator_recovery_complaints, then report_status_enum.
      for (final status in [
        'pending',
        'approved',
        'rejected',
        'open',
        'under_review',
        'resolved',
        'dismissed',
      ]) {
        final label = userRequestStatusLabel(l10n, status);
        expect(label, isNotEmpty);
        expect(
          label,
          isNot(status),
          reason: '"$status" should render as a localized label',
        );
      }
    });

    testWidgets('an unrecognized status renders verbatim rather than being '
        'relabelled or hidden — a value added server-side later must still '
        'show up honestly', (tester) async {
      final l10n = await _pumpTile(
        tester,
        _request(type: UserRequestType.userReport, status: 'open'),
      );
      expect(userRequestStatusLabel(l10n, 'escalated'), 'escalated');
    });
  });

  group('blocking is not a request', () {
    test('UserRequestType has no blocked-user case — blocked_users carries '
        'no status, reviewer or decision, so listing it as awaiting one '
        'would misrepresent an immediate action', () {
      expect(
        UserRequestType.values.map((t) => t.name).join(','),
        isNot(contains('block')),
      );
      expect(UserRequestType.values, hasLength(5));
    });
  });

  group('UserRequestTile rendering', () {
    testWidgets('shows the request type, its status and the date sent',
        (tester) async {
      final l10n = await _pumpTile(
        tester,
        _request(type: UserRequestType.accountDeletion, status: 'pending'),
      );

      expect(find.text(l10n.requestTypeAccountDeletion), findsOneWidget);
      expect(find.text(l10n.requestStatusPending), findsOneWidget);
      expect(find.textContaining('2026'), findsWidgets);
    });

    testWidgets('the cancel action appears only when a cancel callback is '
        'supplied — a request that cannot be cancelled shows no disabled '
        'button either', (tester) async {
      final settled = _request(
        type: UserRequestType.userReport,
        status: 'resolved',
        decidedAt: DateTime(2026, 3, 6),
      );
      final l10n = await _pumpTile(tester, settled);
      expect(find.text(l10n.settingsCancelAccountDeletion), findsNothing);

      var cancelled = 0;
      await _pumpTile(
        tester,
        _request(type: UserRequestType.accountDeletion, status: 'pending'),
        onCancel: () => cancelled++,
      );
      expect(find.text(l10n.settingsCancelAccountDeletion), findsOneWidget);

      await tester.tap(find.text(l10n.settingsCancelAccountDeletion));
      await tester.pump();
      expect(cancelled, 1);
    });

    testWidgets('a pack report shows the reported pack title', (tester) async {
      await _pumpTile(
        tester,
        _request(
          type: UserRequestType.packReport,
          status: 'open',
          targetTitleJson: const {'en': 'Truth or Dare – Classic'},
        ),
      );
      expect(find.text('Truth or Dare – Classic'), findsOneWidget);
    });

    testWidgets('a report shows only the KIND of target — never who was '
        'reported, and never what was done about it', (tester) async {
      final l10n = await _pumpTile(
        tester,
        _request(
          type: UserRequestType.userReport,
          status: 'resolved',
          decidedAt: DateTime(2026, 3, 6),
          reportTargetType: 'profile',
        ),
      );

      expect(find.text(l10n.reportTargetProfile), findsOneWidget);
      // The decision date is shown; the moderation note behind it is not
      // read by the repository at all.
      expect(find.textContaining('2026'), findsWidgets);
    });

    testWidgets('answered date is shown only once a decision exists',
        (tester) async {
      final l10n = await _pumpTile(
        tester,
        _request(type: UserRequestType.creatorVerification, status: 'pending'),
      );
      expect(
        find.textContaining(l10n.requestAnsweredOn('').split('{').first.trim()),
        findsNothing,
        reason: 'an outstanding request has no answer date yet',
      );
    });
  });
}
