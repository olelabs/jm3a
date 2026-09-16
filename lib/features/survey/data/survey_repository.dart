import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/base_repository.dart';

/// Item 5 (Answer our survey) — the app's single, code-defined product
/// feedback survey. Deliberately not a general-purpose survey/form
/// builder (survey_forms/survey_questions/survey_answers) — no such
/// reusable system exists anywhere in this codebase yet (checked: no
/// forms/surveys table, nothing beyond the unrelated `reports` table),
/// and this is one fixed, developer-authored survey, not an admin-
/// configurable one — so the smallest clean schema is a single
/// `survey_responses` row per (user, version), with structured columns
/// for anything analyzable (ratings, multi-select arrays) and plain text
/// columns for free-text answers. See
/// migration_2026_survey_responses.sql's own header comment for the full
/// schema/RLS rationale.
///
/// [currentVersion] is threaded through every call so a FUTURE survey
/// revision is just a new version string — old responses stay valid,
/// distinct, and never conflated with the new ones (the one-response-
/// per-user-per-version UNIQUE constraint keys on this exact string).
class SurveyRepository extends BaseRepository {
  SurveyRepository._();
  static final SurveyRepository _instance = SurveyRepository._();
  static SurveyRepository get instance => _instance;

  final _supabase = Supabase.instance.client;

  /// Bump this when the question set meaningfully changes — a user who
  /// already answered an older version is NOT blocked from answering the
  /// new one (see [hasSubmitted]'s own [version] parameter).
  static const currentVersion = 'v1';

  /// Whether the current user has already submitted [version] — read
  /// before showing the form so "opening it should make the state clear"
  /// (never a silent blank form for someone who already answered, and
  /// never a false "not submitted" that would let a race slip past the
  /// UI-level check before the DB's own UNIQUE constraint catches it).
  Future<bool> hasSubmitted({String version = currentVersion}) => guardedCall(
    operationName: 'surveyHasSubmitted',
    operation: () async {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return false;
      final row = await _supabase
          .from('survey_responses')
          .select('id')
          .eq('user_id', uid)
          .eq('survey_version', version)
          .maybeSingle();
      return row != null;
    },
  );

  /// Submits one full response. Every choice-question value is the
  /// STABLE KEY the option was defined with (see SurveyScreen's own
  /// option-key constants), never the localized display label — so a
  /// future language change or copy edit never changes what's stored,
  /// and the team can aggregate ("most annoying: X") without having to
  /// group by translated strings.
  ///
  /// Duplicate-submission policy: the DB's own UNIQUE(user_id,
  /// survey_version) constraint is the actual authority (see the
  /// migration) — this mirrors FriendsRepository.reportUser's exact
  /// existing precedent for a unique-violation (Postgres code 23505):
  /// caught and treated as an already-idempotently-successful submission
  /// (the user's answer already exists), never surfaced as an error, so
  /// a UI-level race (two rapid taps, or the hasSubmitted check being
  /// stale) can never produce a confusing failure for what is, from the
  /// user's point of view, a successful "I already answered this."
  Future<void> submitSurvey({
    required int overallRating,
    required int recommendScore,
    required List<String> likedMost,
    String? likedMostOther,
    required List<String> annoyances,
    String? annoyancesOther,
    String? confusingFeedback,
    required List<String> wantedFeatures,
    String? wantedFeaturesOther,
    String? moreOftenFeature,
    String? changeOneThing,
    String? additionalFeedback,
    String version = currentVersion,
  }) => guardedCall(
    operationName: 'submitSurvey',
    operation: () async {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) throw Exception('Not authenticated');
      try {
        await _supabase.from('survey_responses').insert({
          'user_id': uid,
          'survey_version': version,
          'overall_rating': overallRating,
          'recommend_score': recommendScore,
          'liked_most': likedMost,
          'liked_most_other': likedMostOther,
          'annoyances': annoyances,
          'annoyances_other': annoyancesOther,
          'confusing_feedback': confusingFeedback,
          'wanted_features': wantedFeatures,
          'wanted_features_other': wantedFeaturesOther,
          'more_often_feature': moreOftenFeature,
          'change_one_thing': changeOneThing,
          'additional_feedback': additionalFeedback,
        });
      } on PostgrestException catch (e) {
        if (e.code == '23505') return; // already submitted — idempotent.
        rethrow;
      }
    },
  );
}
