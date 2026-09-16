// Item 5 (Answer our survey) — pure validation coverage for
// surveyCoreAnswersValid (see lib/features/survey/presentation/screens/
// survey_screen.dart). The two headline metrics (1-5 overall rating,
// 0-10 recommend score) are the only required answers — everything else
// is optional, matching "this should be an optional user survey" at the
// question level while still guaranteeing a submitted response always
// carries its two core, directly-analyzable numbers.
//
// SurveyScreen itself calls SurveyRepository (a raw Supabase.instance
// singleton, not injectable) from initState, so — matching this
// session's established boundary for every other Supabase-singleton-
// backed screen (UserProfileScreen, HomeShellScreen, PlatformConfig-
// gated widgets) — it is not pumped directly here; this tests the one
// genuinely pure decision it makes.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/survey/presentation/screens/survey_screen.dart';

void main() {
  group('surveyCoreAnswersValid', () {
    test('valid when both a rating and a recommend score are given', () {
      expect(
        surveyCoreAnswersValid(overallRating: 3, recommendScore: 7),
        isTrue,
      );
    });

    test('invalid when the rating is unset (0)', () {
      expect(
        surveyCoreAnswersValid(overallRating: 0, recommendScore: 7),
        isFalse,
      );
    });

    test('invalid when the recommend score is unset (-1, the sentinel)', () {
      expect(
        surveyCoreAnswersValid(overallRating: 3, recommendScore: -1),
        isFalse,
      );
    });

    test('the full rating range 1-5 is valid', () {
      for (var r = 1; r <= 5; r++) {
        expect(
          surveyCoreAnswersValid(overallRating: r, recommendScore: 0),
          isTrue,
          reason: 'rating $r should be valid',
        );
      }
    });

    test('a rating above 5 is invalid (defensive — the UI never produces '
        'this, but the check must not silently accept it)', () {
      expect(
        surveyCoreAnswersValid(overallRating: 6, recommendScore: 0),
        isFalse,
      );
    });

    test('the full recommend-score range 0-10 is valid', () {
      for (var s = 0; s <= 10; s++) {
        expect(
          surveyCoreAnswersValid(overallRating: 1, recommendScore: s),
          isTrue,
          reason: 'score $s should be valid',
        );
      }
    });

    test('both unset (the screen\'s initial state) is invalid', () {
      expect(
        surveyCoreAnswersValid(overallRating: 0, recommendScore: -1),
        isFalse,
      );
    });
  });
}
