import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../../shared/widgets/cards/j_card.dart';

/// Item 5 (Answer our survey) — the app's single, optional product
/// feedback survey. A plain single-scroll form with section cards
/// (matches this app's own established idiom for a medium-length form —
/// see edit_profile_screen.dart/forgot_password_screen.dart — rather
/// than introducing a new multi-step wizard pattern for a ~9-question
/// form that fits comfortably on one scroll).
///
/// Never shown for the official account — this screen is only ever
/// reached from ProfileScreen (the signed-in user's OWN profile), which
/// has no isOfficial branch at all (that's UserProfileScreen, viewing
/// someone else — see this app's own established split); the official
/// account's profile UI is completely untouched by this feature.
class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

/// The two headline metrics (star rating, NPS-style recommend score) are
/// the only required answers — everything else is optional free text/
/// multi-select, matching "this should be an optional user survey" at
/// the question level while still guaranteeing a submitted response
/// always has its two core, directly-analyzable numbers. Extracted as a
/// pure top-level function (rather than inlined in _submit) so it's
/// independently unit-testable without pumping the screen, matching this
/// codebase's established pattern for exactly this kind of decision
/// logic (see e.g. resolveJoinByCodeAction, isDiscoverable).
bool surveyCoreAnswersValid({
  required int overallRating,
  required int recommendScore,
}) => overallRating >= 1 && overallRating <= 5 && recommendScore >= 0;

// Stable, never-localized option keys — see SurveyRepository.submitSurvey's
// own doc comment on why these (not display labels) are what gets stored.
const _kOther = 'other';

const _likeChoices = [
  'truth_or_dare',
  'never_have_i_ever',
  'meme_game',
  'packs_marketplace',
  'friends_social',
  'premium_features',
  'honesty_reputation',
  'streaks',
  'official_content',
  _kOther,
];

const _annoyanceChoices = [
  'performance_lag',
  'bugs_glitches',
  'confusing_navigation',
  'notifications',
  'pack_prices',
  'connection_issues',
  'room_management',
  _kOther,
];

const _futureChoices = [
  'more_games',
  'more_packs',
  'better_matchmaking',
  'voice_chat',
  'leaderboards',
  'more_customization',
  'better_notifications',
  _kOther,
];

class _SurveyScreenState extends State<SurveyScreen> {
  bool _isLoading = true;
  bool _alreadySubmitted = false;
  bool _isSubmitting = false;
  bool _justSubmitted = false;

  int _overallRating = 0; // 1-5, 0 = unset
  int _recommendScore = -1; // 0-10, -1 = unset

  String? _likedMost;
  final _likedMostOtherCtrl = TextEditingController();

  final _annoyances = <String>{};
  final _annoyancesOtherCtrl = TextEditingController();
  final _confusingCtrl = TextEditingController();

  final _wantedFeatures = <String>{};
  final _wantedFeaturesOtherCtrl = TextEditingController();
  final _moreOftenCtrl = TextEditingController();

  final _changeOneCtrl = TextEditingController();
  final _additionalCtrl = TextEditingController();

  bool _attempted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _likedMostOtherCtrl.dispose();
    _annoyancesOtherCtrl.dispose();
    _confusingCtrl.dispose();
    _wantedFeaturesOtherCtrl.dispose();
    _moreOftenCtrl.dispose();
    _changeOneCtrl.dispose();
    _additionalCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    bool already = false;
    try {
      already = await sl.surveyRepository.hasSubmitted();
    } catch (_) {
      // Best-effort — if the check fails, fall through to showing the
      // form; the DB's own UNIQUE constraint (and submitSurvey's 23505
      // handling) is still the real duplicate-prevention authority.
    }
    if (!mounted) return;
    setState(() {
      _alreadySubmitted = already;
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    // Item 3's own single-flight idiom, reused here: lock immediately on
    // the first valid tap, before any await, and a second tap while
    // already submitting is a no-op.
    if (_isSubmitting) return;
    if (!surveyCoreAnswersValid(
      overallRating: _overallRating,
      recommendScore: _recommendScore,
    )) {
      setState(() => _attempted = true);
      context.showErrorSnackBar(context.l10n.surveyValidationRequired);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await sl.surveyRepository.submitSurvey(
        overallRating: _overallRating,
        recommendScore: _recommendScore,
        likedMost: _likedMost == null ? [] : [_likedMost!],
        likedMostOther: _likedMost == _kOther
            ? _likedMostOtherCtrl.text.trim()
            : null,
        annoyances: _annoyances.toList(),
        annoyancesOther: _annoyances.contains(_kOther)
            ? _annoyancesOtherCtrl.text.trim()
            : null,
        confusingFeedback: _confusingCtrl.text.trim().isEmpty
            ? null
            : _confusingCtrl.text.trim(),
        wantedFeatures: _wantedFeatures.toList(),
        wantedFeaturesOther: _wantedFeatures.contains(_kOther)
            ? _wantedFeaturesOtherCtrl.text.trim()
            : null,
        moreOftenFeature: _moreOftenCtrl.text.trim().isEmpty
            ? null
            : _moreOftenCtrl.text.trim(),
        changeOneThing: _changeOneCtrl.text.trim().isEmpty
            ? null
            : _changeOneCtrl.text.trim(),
        additionalFeedback: _additionalCtrl.text.trim().isEmpty
            ? null
            : _additionalCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _justSubmitted = true;
      });
    } catch (e) {
      // On failure: unlock and let the user retry — every answer already
      // entered is still sitting in local state/controllers, nothing is
      // cleared.
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      context.showErrorSnackBar(context.l10n.errorUnexpected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.surveyTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_alreadySubmitted || _justSubmitted)
          ? _SurveyDoneView(justSubmitted: _justSubmitted)
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.surveyIntro,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _SurveySection(
                    title: l10n.surveySectionOverall,
                    children: [
                      Text(
                        l10n.surveyQ1Label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(
                          5,
                          (i) => GestureDetector(
                            onTap: () =>
                                setState(() => _overallRating = i + 1),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                i < _overallRating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 36,
                                color: AppColors.amberOrangeLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_attempted && _overallRating < 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l10n.surveyValidationRequired,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.surveyQ2Label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(
                          11,
                          (i) => _NpsChip(
                            value: i,
                            selected: _recommendScore == i,
                            onTap: () => setState(() => _recommendScore = i),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.surveyRecommendNotLikely,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              l10n.surveyRecommendVeryLikely,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_attempted && _recommendScore < 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l10n.surveyValidationRequired,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),

                  _SurveySection(
                    title: l10n.surveySectionLikes,
                    children: [
                      Text(
                        l10n.surveyQ3Label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final key in _likeChoices)
                            ChoiceChip(
                              label: Text(_choiceLabel(l10n, key)),
                              selected: _likedMost == key,
                              onSelected: (_) =>
                                  setState(() => _likedMost = key),
                            ),
                        ],
                      ),
                      if (_likedMost == _kOther) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _likedMostOtherCtrl,
                          decoration: InputDecoration(
                            hintText: l10n.surveyOtherHint,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ),

                  _SurveySection(
                    title: l10n.surveySectionProblems,
                    children: [
                      Text(
                        l10n.surveyQ4Label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final key in _annoyanceChoices)
                            FilterChip(
                              label: Text(_choiceLabel(l10n, key)),
                              selected: _annoyances.contains(key),
                              onSelected: (sel) => setState(() {
                                if (sel) {
                                  _annoyances.add(key);
                                } else {
                                  _annoyances.remove(key);
                                }
                              }),
                            ),
                        ],
                      ),
                      if (_annoyances.contains(_kOther)) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _annoyancesOtherCtrl,
                          decoration: InputDecoration(
                            hintText: l10n.surveyOtherHint,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        l10n.surveyQ5Label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _confusingCtrl,
                        maxLines: 3,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),

                  _SurveySection(
                    title: l10n.surveySectionFuture,
                    children: [
                      Text(
                        l10n.surveyQ6Label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final key in _futureChoices)
                            FilterChip(
                              label: Text(_choiceLabel(l10n, key)),
                              selected: _wantedFeatures.contains(key),
                              onSelected: (sel) => setState(() {
                                if (sel) {
                                  _wantedFeatures.add(key);
                                } else {
                                  _wantedFeatures.remove(key);
                                }
                              }),
                            ),
                        ],
                      ),
                      if (_wantedFeatures.contains(_kOther)) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _wantedFeaturesOtherCtrl,
                          decoration: InputDecoration(
                            hintText: l10n.surveyOtherHint,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        l10n.surveyQ7Label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _moreOftenCtrl,
                        maxLines: 3,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),

                  _SurveySection(
                    title: l10n.surveySectionOpen,
                    children: [
                      Text(
                        l10n.surveyQ8Label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _changeOneCtrl,
                        maxLines: 3,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.surveyQ9Label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _additionalCtrl,
                        maxLines: 3,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  JButton(
                    label: l10n.surveySubmitButton,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                ],
              ),
            ),
    );
  }

  String _choiceLabel(dynamic l10n, String key) => switch (key) {
    'truth_or_dare' => l10n.surveyChoiceTruthOrDare as String,
    'never_have_i_ever' => l10n.surveyChoiceNhie as String,
    'meme_game' => l10n.surveyChoiceMeme as String,
    'packs_marketplace' => l10n.surveyChoicePacks as String,
    'friends_social' => l10n.surveyChoiceFriends as String,
    'premium_features' => l10n.surveyChoicePremium as String,
    'honesty_reputation' => l10n.surveyChoiceReputation as String,
    'streaks' => l10n.surveyChoiceStreaks as String,
    'official_content' => l10n.surveyChoiceOfficialContent as String,
    'performance_lag' => l10n.surveyChoicePerformance as String,
    'bugs_glitches' => l10n.surveyChoiceBugs as String,
    'confusing_navigation' => l10n.surveyChoiceNavigation as String,
    'notifications' => l10n.surveyChoiceNotifications as String,
    'pack_prices' => l10n.surveyChoicePackPrices as String,
    'connection_issues' => l10n.surveyChoiceConnection as String,
    'room_management' => l10n.surveyChoiceRoomManagement as String,
    'more_games' => l10n.surveyChoiceMoreGames as String,
    'more_packs' => l10n.surveyChoiceMorePacks as String,
    'better_matchmaking' => l10n.surveyChoiceMatchmaking as String,
    'voice_chat' => l10n.surveyChoiceVoiceChat as String,
    'leaderboards' => l10n.surveyChoiceLeaderboards as String,
    'more_customization' => l10n.surveyChoiceCustomization as String,
    'better_notifications' => l10n.surveyChoiceBetterNotifications as String,
    _kOther => l10n.surveyChoiceOther as String,
    _ => key,
  };
}

class _SurveySection extends StatelessWidget {
  const _SurveySection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: JCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ).animate().fadeIn(),
    );
  }
}

class _NpsChip extends StatelessWidget {
  const _NpsChip({
    required this.value,
    required this.selected,
    required this.onTap,
  });
  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          '$value',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _SurveyDoneView extends StatelessWidget {
  const _SurveyDoneView({required this.justSubmitted});
  final bool justSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 64,
              color: AppColors.nhieGreen,
            ).animate().scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(1, 1),
            ),
            const SizedBox(height: 16),
            Text(
              justSubmitted
                  ? l10n.surveySuccessTitle
                  : l10n.surveyAlreadySubmittedTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              justSubmitted
                  ? l10n.surveySuccessBody
                  : l10n.surveyAlreadySubmittedBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
