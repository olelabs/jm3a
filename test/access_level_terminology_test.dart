// Pre-release terminology pass — Jma3a Plus / Jma3a Elite are access levels
// granted by the Jma3a team (internal tiers `premium` / `premium_plus`,
// unchanged), and packs are things a user gets access to, not purchases.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/features/auth/domain/entities/user_entity.dart';
import 'package:jma3a/features/notifications/domain/notification_entity.dart';
import 'package:jma3a/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:jma3a/features/premium/presentation/widgets/access_levels_section.dart';

const _locales = ['en', 'ar', 'fr'];

/// Subscription / renewal / purchase vocabulary, plus the old level names
/// and the raw internal tier id, in every shipped locale.
const _banned = [
  'subscri', 'renew', 'purchas', 'repurchase', 'bought', 'payment', 'paid',
  'premium', 'abonnement', 'renouvel', 'achet', 'rachet', 'paiement',
  'اشتراك', 'جدده', 'تجديد', 'شراء', 'بريميوم', 'مميز بلس', 'الدفع',
];

void _expectClean(String text, {required String where}) {
  // ICU placeholders ({premiumLimit}) are identifiers, not displayed text.
  final lower = text.replaceAll(RegExp(r'\{[^}]*\}'), '').toLowerCase();
  for (final word in _banned) {
    expect(lower.contains(word), isFalse, reason: '"$word" in $where: $text');
  }
}

NotificationEntity _notif(
  NotificationType type, {
  Map<String, dynamic> data = const {},
  Map<String, dynamic>? title,
  Map<String, dynamic>? body,
}) => NotificationEntity(
  id: 'n',
  userId: 'u',
  type: type,
  titleJson: title ?? const {'en': 'stored title'},
  bodyJson: body ?? const {'en': 'stored body'},
  data: data,
  isRead: false,
  createdAt: DateTime(2026),
);

UserEntity _user({bool premium = false, String? tier, DateTime? expires}) =>
    UserEntity(
      id: 'u',
      email: 'u@t.co',
      isPremium: premium,
      premiumTier: tier,
      premiumExpiresAt: expires,
    );

void main() {
  group('access-level notification display copy', () {
    final cases = <(NotificationType, Map<String, dynamic>)>[
      (NotificationType.subscriptionStarted, {'tier': 'premium'}),
      (NotificationType.subscriptionStarted, {'tier': 'premium_plus'}),
      (NotificationType.subscriptionExpiring2d, {'tier': 'premium_plus'}),
      (NotificationType.subscriptionExpiring1d, {'tier': 'premium'}),
      (NotificationType.subscriptionExpired, {'tier': 'premium_plus'}),
      (NotificationType.creatorPacksTransferred, {}),
      (NotificationType.creatorPrivilegesRemoved, {}),
      (NotificationType.system, {'reason': 'packs_restored_grace'}),
      (NotificationType.packExpired, {'pack_name': 'Party Pack'}),
      (NotificationType.packExpired, {}),
    ];

    for (final (type, data) in cases) {
      test('$type $data has clean copy in every locale', () {
        final copy = accessLevelNotificationCopy(type, data);
        expect(copy, isNotNull);
        for (final l in _locales) {
          expect(copy!.title[l], isNotEmpty);
          expect(copy.body[l], isNotEmpty);
          _expectClean('${copy.title[l]} ${copy.body[l]}', where: '$type/$l');
        }
      });
    }

    test('replaces old stored "subscription/renew" text and raw tier id', () {
      final n = _notif(
        NotificationType.subscriptionExpired,
        data: {'tier': 'premium_plus'},
        title: {'en': 'Premium Expired'},
        body: {
          'en': 'Your premium_plus subscription has expired. Renew to keep '
              'your perks.',
        },
      );
      expect(n.titleFor('en'), 'Jma3a Elite access ended');
      expect(n.bodyFor('en'), contains('Your Jma3a Elite access has ended'));
      expect(n.bodyFor('en'), isNot(contains('premium_plus')));
    });

    test('granted copy says the team granted the level (never "bought")', () {
      final plus = _notif(
        NotificationType.subscriptionStarted,
        data: {'tier': 'premium'},
      );
      expect(plus.titleFor('en'), "✦ You've been granted Jma3a Plus access!");
      final elite = _notif(
        NotificationType.subscriptionStarted,
        data: {'tier': 'premium_plus'},
      );
      expect(elite.bodyFor('fr'), contains('Jma3a Elite'));
      expect(elite.bodyFor('ar'), contains('جماعة إيليت'));
    });

    test('toasts (and the local notification built from them) agree', () {
      final toast = InAppToast(
        id: 't',
        type: NotificationType.packExpired,
        titleJson: const {'en': 'Pack Access Expired'},
        bodyJson: const {'en': 'Repurchase to keep playing it.'},
        data: const {'pack_name': 'Party Pack'},
        createdAt: DateTime(2026),
      );
      expect(toast.bodyFor('en'), 'Your access to "Party Pack" has ended.');
    });

    test('every other notification keeps its stored text', () {
      for (final type in [
        NotificationType.friendRequest,
        NotificationType.packGranted,
        NotificationType.packSale,
        NotificationType.physicalPackStatus,
        NotificationType.roomInvite,
      ]) {
        expect(accessLevelNotificationCopy(type, const {}), isNull);
        expect(_notif(type).titleFor('en'), 'stored title');
      }
      // A system message that is not the grace-period restore is untouched.
      expect(_notif(NotificationType.system).bodyFor('en'), 'stored body');
    });
  });

  group('notification settings list', () {
    test('hides rows with no producer or a payment-only flow', () {
      for (final hidden in [
        NotificationType.walletCredit,
        NotificationType.walletDebit,
        NotificationType.packSale,
        NotificationType.achievement,
        NotificationType.subscriptionExpiring2d,
        NotificationType.subscriptionExpiring1d,
      ]) {
        expect(visiblePreferenceTypes, isNot(contains(hidden)));
      }
    });

    test('keeps every genuinely produced, user-relevant type', () {
      for (final kept in [
        NotificationType.friendRequest,
        NotificationType.friendAccepted,
        NotificationType.follow,
        NotificationType.roomInvite,
        NotificationType.roomStarted,
        NotificationType.roomJoinRequest,
        NotificationType.roomJoinRequestAccepted,
        NotificationType.roomJoinRequestRejected,
        NotificationType.roomKicked,
        NotificationType.moderation,
        NotificationType.chatMessage,
        NotificationType.packApproved,
        NotificationType.packRejected,
        NotificationType.packReview,
        NotificationType.packGranted,
        NotificationType.packExpired,
        NotificationType.physicalPackStatus,
        NotificationType.subscriptionStarted,
        NotificationType.subscriptionExpired,
        NotificationType.creatorPacksTransferred,
        NotificationType.creatorPrivilegesRemoved,
        NotificationType.creatorRecoveryApproved,
        NotificationType.creatorRecoveryRejected,
        NotificationType.streakIncreased,
        NotificationType.system,
      ]) {
        expect(visiblePreferenceTypes, contains(kept));
      }
    });

    test('visible setting labels use access/pack wording, not payment', () {
      final labels = [
        'notifTypeSubscriptionStarted',
        'notifTypeSubscriptionExpired',
        'notifTypeSubscriptionExpiring1d',
        'notifTypeSubscriptionExpiring2d',
        'notifTypePackGranted',
        'notifTypePackExpired',
      ];
      for (final l in _locales) {
        final arb =
            jsonDecode(File('lib/core/l10n/app_$l.arb').readAsStringSync())
                as Map<String, dynamic>;
        for (final key in labels) {
          _expectClean(arb[key] as String, where: '$key/$l');
        }
      }
    });
  });

  group('l10n: no Premium/subscription wording left in user-facing strings', () {
    // Keys that describe REAL money flows that still exist: creator pack
    // pricing (packs are priced for the Jma3a Store), physical printed-pack
    // orders charged to the wallet, and the survey's "pack prices" option.
    const allowed = {
      'packMinPriceError',
      'packTermsBody',
      'packStagePaymentConfirmed',
      'packPhysicalFeeNotice',
    };
    for (final l in _locales) {
      test('app_$l.arb', () {
        final arb =
            jsonDecode(File('lib/core/l10n/app_$l.arb').readAsStringSync())
                as Map<String, dynamic>;
        arb.forEach((key, value) {
          if (key.startsWith('@') || value is! String) return;
          if (allowed.contains(key)) return;
          _expectClean(value, where: '$key/$l');
        });
      });
    }
  });

  group('access level mapping', () {
    test('internal tiers map to the new names', () {
      expect(accessLevelOf(null), AccessLevel.basic);
      expect(accessLevelOf(_user()), AccessLevel.basic);
      expect(accessLevelOf(_user(premium: true, tier: 'premium')), AccessLevel.plus);
      expect(
        accessLevelOf(_user(premium: true, tier: 'premium_plus')),
        AccessLevel.elite,
      );
    });

    test('an ended access level shows as basic (same rule as the gates)', () {
      final ended = _user(
        premium: true,
        tier: 'premium_plus',
        expires: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(ended.isPremiumActive, isFalse);
      expect(accessLevelOf(ended), AccessLevel.basic);
    });

    test('displayed player caps match UserEntity.roomPlayerCap', () {
      expect(
        _user(premium: true, tier: 'premium').roomPlayerCap,
        kPlusRoomPlayerCap,
      );
      expect(
        _user(premium: true, tier: 'premium_plus').roomPlayerCap,
        kEliteRoomPlayerCap,
      );
    });

    test('tier labels', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(accessTierLabel(l10n, 'premium'), 'Jma3a Plus');
      expect(accessTierLabel(l10n, 'premium_plus'), 'Jma3a Elite');
      expect(accessLevelLabel(l10n, AccessLevel.basic), 'Basic access');
    });
  });

  group('AccessLevelsSection', () {
    Future<void> pump(
      WidgetTester tester, {
      AccessLevel current = AccessLevel.basic,
      VoidCallback? onRequest,
      bool creator = true,
      Locale locale = const Locale('en'),
    }) async {
      tester.view.physicalSize = const Size(1080, 6000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: AccessLevelsSection(
                current: current,
                roomsPerDay: 15,
                offlinePacks: 10,
                includeCreatorEligibility: creator,
                onRequestConsideration: onRequest,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Jma3a Plus first, Jma3a Elite last as the highest level', (
      tester,
    ) async {
      await pump(tester, onRequest: () {});
      final plus = find.byKey(const ValueKey('access-level-plus'));
      final elite = find.byKey(const ValueKey('access-level-elite'));
      expect(plus, findsOneWidget);
      expect(elite, findsOneWidget);
      expect(
        tester.getTopLeft(elite).dy,
        greaterThan(tester.getBottomLeft(plus).dy),
      );
      // Nothing in the section renders below the Elite card.
      final section = find.byType(AccessLevelsSection);
      expect(
        tester.getBottomLeft(elite).dy,
        moreOrLessEquals(tester.getBottomLeft(section).dy),
      );
      expect(
        find.descendant(of: elite, matching: find.text('Highest level')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: elite,
          matching: find.text('Everything in Jma3a Plus, plus:'),
        ),
        findsOneWidget,
      );
      expect(find.text('Create up to 15 rooms per day'), findsOneWidget);
      expect(find.text('Up to 8 players in rooms you create'), findsOneWidget);
      expect(find.text('Up to 12 players in rooms you create'), findsOneWidget);
      expect(find.text('Your current access: Basic access'), findsOneWidget);
    });

    testWidgets('explains the levels are granted, never sold', (tester) async {
      await pump(tester, onRequest: () {});
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(texts, contains('granted by the Jma3a team'));
      _expectClean(texts, where: 'AccessLevelsSection');
      for (final w in ['buy', 'price', 'checkout', 'upgrade']) {
        expect(texts.toLowerCase(), isNot(contains(w)));
      }
    });

    testWidgets('request button calls back; hidden at the highest level', (
      tester,
    ) async {
      var taps = 0;
      await pump(tester, onRequest: () => taps++);
      await tester.tap(find.text('Ask the Jma3a team to consider you'));
      expect(taps, 1);

      await pump(tester, current: AccessLevel.elite, onRequest: () => taps++);
      expect(find.text('Ask the Jma3a team to consider you'), findsNothing);
      expect(find.text('Your level'), findsOneWidget);
    });

    testWidgets('creator eligibility item follows the live requirement flag', (
      tester,
    ) async {
      await pump(tester, creator: false);
      expect(
        find.textContaining('Verified Creator status'),
        findsNothing,
      );
      await pump(tester, creator: true);
      expect(find.textContaining('Verified Creator status'), findsOneWidget);
    });

    testWidgets('renders in Arabic (RTL) without overflow', (tester) async {
      await pump(tester, locale: const Locale('ar'), onRequest: () {});
      expect(tester.takeException(), isNull);
      expect(find.text('جماعة إيليت'), findsWidgets);
    });
  });
}
