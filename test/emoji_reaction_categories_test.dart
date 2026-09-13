// Item 6 (reaction-expansion pass) — regression coverage for:
// 1. kEmojiReactions/kReactionKeys stability: the original entries must
//    never move or change (their literal value IS the reaction's id —
//    see AnimatedReactionOverlay/EmojiReactionRow, which key everything
//    off the string itself, never a list index).
// 2. kEmojiReactionCategories fully and exactly covers kEmojiReactions
//    (every reaction appears in exactly one category, nothing invented).
// 3. The expanded picker sheet actually opens, scrolls, and lets a user
//    pick a reaction without overflowing — the concrete risk introduced
//    by roughly doubling the item count in a sheet that used to size
//    itself to fit everything unconditionally.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/Sticker.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/theme/j_theme_extension.dart';
import 'package:jma3a/features/avatar/presentation/avatar_creator_screen.dart';

const _originalEmojiReactions = [
  '😂',
  '❤️',
  '🔥',
  '💀',
  '👏',
  '🤣',
  '😭',
  '🫡',
  '💯',
  '🤯',
  '👑',
  '😤',
  '🥹',
  '🫶',
  '💅',
  '🙈',
  '😎',
  '🤡',
  '💔',
  '🎉',
  '😈',
];

const _originalReactionKeys = [
  'laugh',
  'fire',
  'dead',
  'clap',
  'rofl',
  'cry',
  'salute',
  'hundred',
  'mindblown',
  'crown',
  'annoyed',
  'touched',
];

Widget _wrap(Widget child) => MaterialApp(
  theme: ThemeData(extensions: const [JThemeExtension.light]),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  group('kEmojiReactions — stability + expansion (item 6)', () {
    test('every original reaction is still present, in its original order', () {
      for (var i = 0; i < _originalEmojiReactions.length; i++) {
        expect(kEmojiReactions[i], _originalEmojiReactions[i]);
      }
    });

    test('substantially more reactions than before (at least double)', () {
      expect(
        kEmojiReactions.length,
        greaterThanOrEqualTo(_originalEmojiReactions.length * 2),
      );
    });

    test('no duplicate reactions', () {
      expect(kEmojiReactions.toSet().length, kEmojiReactions.length);
    });
  });

  group('kReactionKeys — avatar reaction stability + expansion (item 6)', () {
    test('every original key is still present, in its original order', () {
      for (var i = 0; i < _originalReactionKeys.length; i++) {
        expect(kReactionKeys[i], _originalReactionKeys[i]);
      }
    });

    test(
      'substantially more avatar reactions than before (at least double)',
      () {
        expect(
          kReactionKeys.length,
          greaterThanOrEqualTo(_originalReactionKeys.length * 2),
        );
      },
    );

    test('no duplicate keys', () {
      expect(kReactionKeys.toSet().length, kReactionKeys.length);
    });

    test(
      'every key resolves to a real AvatarConfig.reactionExpressions entry',
      () {
        for (final key in kReactionKeys) {
          expect(
            AvatarConfig.reactionExpressions.containsKey(key),
            isTrue,
            reason: key,
          );
        }
      },
    );

    test('every expression is a genuinely distinct eye/mouth/eyebrow '
        'combination — no new key silently renders identically to another', () {
      final seen = <String>{};
      for (final key in kReactionKeys) {
        final e = AvatarConfig.reactionExpressions[key]!;
        final signature = '${e.eyeType}|${e.mouthType}|${e.eyebrowType}';
        expect(
          seen.add(signature),
          isTrue,
          reason: '$key duplicates another expression\'s combination',
        );
      }
    });
  });

  group('kEmojiReactionCategories — full, exact coverage (item 6)', () {
    test(
      'every reaction in kEmojiReactions appears in exactly one category',
      () {
        final counts = <String, int>{};
        for (final list in kEmojiReactionCategories.values) {
          for (final emoji in list) {
            counts[emoji] = (counts[emoji] ?? 0) + 1;
          }
        }
        for (final emoji in kEmojiReactions) {
          expect(counts[emoji], 1, reason: '$emoji should appear exactly once');
        }
        // And nothing in the categories that isn't a real reaction.
        for (final emoji in counts.keys) {
          expect(kEmojiReactions.contains(emoji), isTrue, reason: emoji);
        }
      },
    );
  });

  group('EmojiReactionRow — expanded picker (item 6)', () {
    testWidgets(
      'opening the icon picker shows category headers and lets a user '
      'pick a reaction without overflow',
      (tester) async {
        String? picked;
        await tester.pumpWidget(
          _wrap(
            EmojiReactionRow(
              reactionsByEmoji: const {},
              alreadyReacted: false,
              onReact: (v) => picked = v,
              useAvatarMode: true,
              ownAvatarConfig: AvatarConfig.defaults.toMap(),
            ),
          ),
        );
        await tester.tap(find.text('Icons'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // At least one category header from the new grouping is visible.
        expect(find.text('Popular'), findsOneWidget);

        await tester.tap(find.text('🔥').first);
        await tester.pumpAndSettle();
        expect(picked, '🔥');
      },
    );

    // A parallel "open the Avatars tab and check for overflow" test was
    // deliberately not added here: each avatar tile fetches its
    // expression's avataaars.io SVG over the network, and that fetch's
    // failure/error surfaces asynchronously (via flutter_svg's compute()
    // isolate) AFTER the test body has already returned — outside what
    // tester.takeException() can catch, unlike a synchronous render
    // error (see animated_reaction_overlay_test.dart's identical, already
    // -documented limitation for the same UserAvatar/SVG dependency).
    // The Avatars tab reuses the EXACT SAME _ReactionPickerSheet
    // scrollable-container structure the Icons-tab test above already
    // exercises (same Flexible + bounded-height Container, same
    // GridView.builder with real scroll physics instead of the old
    // shrinkWrap-everything version) — verified by code review, not a
    // second widget test, since the sheet doesn't branch that structure
    // by avatars vs. icons, only by categorized-vs-flat content.
  });
}
