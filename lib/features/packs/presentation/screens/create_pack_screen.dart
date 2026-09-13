import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/platform_config_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../../shared/widgets/game/game_card_preview.dart';
import '../../../../shared/widgets/media/signed_network_image.dart';
import '../../data/pack_repository.dart';
import '../../data/pack_upload_service.dart';
import '../../domain/pack_situation_tags.dart';
import '../pack_provider.dart';
import '../widgets/pack_situation_tag_picker.dart';

/// Multi-step pack creation flow.
/// Steps: 1. Info  2. Cover  3. Cards  4. Review & Publish
class CreatePackScreen extends StatefulWidget {
  const CreatePackScreen({super.key, this.existingPackId, this.existingPack});
  final String? existingPackId;
  final PackEntity? existingPack;

  @override
  State<CreatePackScreen> createState() => _CreatePackScreenState();
}

class _CreatePackScreenState extends State<CreatePackScreen> {
  late final PackDraft _draft;
  int _step = 0;
  bool _isSaving = false;
  late String? _savedPackId;

  @override
  void initState() {
    super.initState();
    _savedPackId = widget.existingPackId;
    // Pre-fill draft from existing pack
    final p = widget.existingPack;
    if (p != null) {
      final titles = Map<String, String>.from(p.titleJson);
      final descriptions = Map<String, String>.from(p.descriptionJson ?? {});
      // Restore the REAL languages this draft was created with — never force
      // 'en'. availableLanguages is derived from the pack's actual per-language
      // title content (see PackRepository._parseAvailableLanguages); fall back
      // to the title keys, and only to an empty list (creator re-picks) for a
      // degenerate draft with no content at all.
      final selectedLanguages = p.availableLanguages.isNotEmpty
          ? List<String>.from(p.availableLanguages)
          : titles.keys.toList();
      _draft = PackDraft(
        titles: titles,
        descriptions: descriptions,
        selectedLanguages: selectedLanguages,
        gameType: p.gameType,
        language: p.language,
        priceMru: p.priceMru,
        categoryId: p.categoryId,
        allowSpicy: p.hasSpicy,
        coverImageUrl: p.coverImageUrl,
        cards: [],
        minAge: p.minAge,
        maxAge: p.maxAge,
        genderRestriction: p.genderRestriction,
        minPlayers: p.minPlayers,
        maxPlayers: p.maxPlayers,
        suggestedPunishments: List<String>.from(p.suggestedPunishments),
      );
      // Jump to cards step if basic info already saved
      _step = _savedPackId != null ? _activeSteps.indexOf('cards') : 0;
    } else {
      _draft = PackDraft();
    }
  }

  // Order: general info (incl. cover) -> languages -> names & descriptions
  // -> audience -> cards -> [reactions | punishments, game-type specific]
  // -> publish. "Cards" always sits at a fixed index (4) regardless of game
  // type since only what comes *after* it varies.
  // Internal routing keys — stable identifiers, never shown to the user and
  // never translated. Display labels are derived separately via
  // _stepLabel(context, key) so switching locales can't break step routing
  // (the switch-statement in build() and _saveOnAdvanceSteps below both key
  // off these, not off the localized label).
  static const _baseSteps = [
    'general_info',
    'languages',
    'names_descriptions',
    'audience',
    'cards',
  ];
  List<String> get _activeSteps => [
    ..._baseSteps,
    if (_draft.gameType == 'meme_game') 'reactions',
    if (_draft.gameType == 'truth_or_dare') 'punishments',
    'publish',
  ];

  String _stepLabel(BuildContext context, String key) => switch (key) {
    'general_info' => context.l10n.packStepGeneralInfo,
    'languages' => context.l10n.packStepLanguages,
    'names_descriptions' => context.l10n.packStepNamesDescriptions,
    'audience' => context.l10n.packStepAudience,
    'cards' => context.l10n.packStepCards,
    'reactions' => context.l10n.packStepReactions,
    'punishments' => context.l10n.packStepPunishments,
    _ => context.l10n.packStepPublish,
  };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back must walk the wizard backward, not tear it down. Only the FIRST
      // step is allowed to actually pop the route (leaving creation); every
      // later step intercepts Back — app-bar back button AND the Android system
      // back both route through here — and returns to the previous step with
      // the draft fully intact. The draft is never discarded by going back.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, __) {
        if (didPop) {
          if (mounted) context.read<PackProvider>().loadCreatedPacks();
          return;
        }
        if (_step > 0) _prevStep();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.l10n.packCreateTitle(
              _stepLabel(context, _activeSteps[_step]),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_step + 1) / _activeSteps.length,
              minHeight: 4,
              color: AppColors.navyBlue,
              backgroundColor: context.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey(_step),
            child: switch (_activeSteps[_step]) {
              'general_info' => _GeneralInfoStep(
                draft: _draft,
                onNext: _nextStep,
              ),
              'languages' => _LanguageStep(draft: _draft, onNext: _nextStep),
              'names_descriptions' => _NamesStep(
                draft: _draft,
                onNext: _nextStep,
              ),
              'audience' => _AudienceStep(draft: _draft, onNext: _nextStep),
              'cards' => _CardsStep(
                draft: _draft,
                packId: _savedPackId,
                onNext: _nextStep,
                onBack: _prevStep,
              ),
              'reactions' => _ReactionsStep(
                draft: _draft,
                packId: _savedPackId,
                onNext: _nextStep,
                onBack: _prevStep,
              ),
              'punishments' => _PunishmentsStep(
                draft: _draft,
                onNext: _nextStep,
                onBack: _prevStep,
              ),
              _ => _PublishStep(
                draft: _draft,
                packId: _savedPackId,
                isSaving: _isSaving,
                onPublish: _submit,
                onBack: _prevStep,
              ),
            },
          ),
        ),
      ),
    );
  }

  // Steps that edit fields directly on `_draft` and must persist them via
  // createPackDraft/updatePackDraft before moving on. General Info and
  // Languages are excluded deliberately: General Info happens before a
  // title exists (the backend create route 400s without one) and Languages
  // only sets selectedLanguages, so neither has anything persistable yet.
  // Cards/Reactions are excluded because they persist through their own
  // per-item API calls keyed on _savedPackId, not through this draft
  // object.
  static const _saveOnAdvanceSteps = {
    'names_descriptions',
    'audience',
    'punishments',
  };

  void _nextStep() {
    if (_saveOnAdvanceSteps.contains(_activeSteps[_step])) {
      _saveDraft();
    } else {
      setState(() => _step = (_step + 1).clamp(0, _activeSteps.length - 1));
    }
  }

  void _prevStep() =>
      setState(() => _step = (_step - 1).clamp(0, _activeSteps.length - 1));

  Future<void> _saveDraft() async {
    final targetStep = (_step + 1).clamp(0, _activeSteps.length - 1);
    setState(() => _isSaving = true);
    try {
      final packs = context.read<PackProvider>();
      final userId = packs.currentUserId;
      if (userId == null) throw Exception(context.l10n.packNotLoggedIn);

      PackEntity pack;
      if (_savedPackId == null) {
        pack = await PackRepository.instance.createPackDraft(_draft, userId);
        _savedPackId = pack.id;
      } else {
        pack = await PackRepository.instance.updatePackDraft(
          _savedPackId!,
          _draft,
        );
      }
      // The Node API's create/update routes don't carry this field yet, so
      // it's linked via a direct client write once a pack id exists — see
      // linkPendingCategorySuggestion.
      if (_draft.pendingCategorySuggestionId != null) {
        await PackRepository.instance.linkPendingCategorySuggestion(
          _savedPackId!,
          _draft.pendingCategorySuggestionId!,
        );
      }
      setState(() {
        _isSaving = false;
        _step = targetStep;
      });
    } on ConflictFailure catch (e) {
      // The very first save of a brand-new pack races the database's
      // idx_packs_one_draft_per_creator constraint (e.g. two devices, or a
      // stale dashboard pre-check) — no pack was created here (_savedPackId
      // stays null), so there's nothing to keep editing; back out to the
      // dashboard with a clear explanation instead of leaving the wizard
      // stuck on step 0 with no persisted draft under it.
      setState(() => _isSaving = false);
      if (mounted) {
        final message = e.code == 'draft_limit_reached'
            ? context.l10n.packAlreadyHasDraft
            : e.message;
        context.showErrorSnackBar(message);
        if (_savedPackId == null) context.pop();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted)
        context.showErrorSnackBar(context.l10n.packFailedToSave(e.toString()));
    }
  }

  Future<bool> _confirmSubmissionFee() async {
    // The fee is admin-configurable via app_settings (never hardcoded) —
    // submit_pack_for_review always charges the live server-side value
    // regardless of what's shown here; PlatformConfigProvider's cached
    // value is purely so the dialog text is accurate.
    final fee = context.read<PlatformConfigProvider>().packExtraCreationFeeMru;
    if (!mounted) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.packAdditionalFeeTitle),
        content: Text(ctx.l10n.packAdditionalFeeBody(fee)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.packPayFeeAndSubmit(fee)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  /// [payFee] true skips straight to a paid submission (used on retry after
  /// the server itself reported fee_required) — otherwise runs the
  /// non-authoritative pre-check first purely to decide whether to show the
  /// confirmation dialog before calling the RPC, which always re-verifies
  /// the real limit server-side regardless of what the pre-check found.
  Future<void> _submit({bool payFee = false}) async {
    if (_savedPackId == null) return;

    if (!payFee) {
      try {
        final status = await PackRepository.instance.getPackCreationStatus();
        if (!status.canSubmitFree) {
          if (!mounted) return;
          if (!await _confirmSubmissionFee()) return;
          payFee = true;
        }
      } catch (_) {
        // Pre-check is best-effort only — fall through and let the RPC's
        // own authoritative check decide (may still surface fee_required
        // below, handled the same way as a fresh confirmation).
      }
    }

    setState(() => _isSaving = true);
    try {
      await PackRepository.instance.submitForReview(
        _savedPackId!,
        payFee: payFee,
      );
      if (mounted) {
        context.read<PackProvider>().loadCreatedPacks();
        context.showSnackBar(context.l10n.packSubmittedForReviewNotice);
        context.pop();
      }
    } on PaymentFailure catch (e) {
      setState(() => _isSaving = false);
      if (e.code == 'fee_required' && mounted) {
        // The pre-check missed it (race) — the server has now confirmed a
        // fee is actually required, so ask once more and submit paid.
        if (await _confirmSubmissionFee()) await _submit(payFee: true);
      } else if (mounted) {
        context.showErrorSnackBar(e.message);
      }
    } on Failure catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        // creator_not_verified gets the fully localized message; every
        // other known business error (a content gate, pack_not_editable,
        // ...) already carries a reasonable message from the repository's
        // own error mapping, shown directly rather than falling through
        // to the generic packSubmissionFailed(e.toString()) wrapper below.
        context.showErrorSnackBar(
          switch (e.code) {
            'creator_not_verified' => context.l10n.packCreatorNotVerified,
            'spicy_content_disabled' =>
              context.l10n.packSpicyContentDisabled,
            _ => e.message,
          },
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        context.showErrorSnackBar(
          context.l10n.packSubmissionFailed(e.toString()),
        );
      }
    }
  }
}

// ── Category picker ───────────────────────────────────────────────────────────
class _CategoryPicker extends StatefulWidget {
  const _CategoryPicker({
    required this.gameType,
    required this.selectedId,
    required this.onSelected,
    this.pendingSuggestionId,
    this.onSuggested,
  });
  final String gameType;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final String? pendingSuggestionId;
  final ValueChanged<String>? onSuggested;
  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  List<PackCategory>? _cats;
  bool _loading = false;
  Map<String, dynamic>? _suggestion;

  @override
  void initState() {
    super.initState();
    _load();
    _loadSuggestion();
  }

  @override
  void didUpdateWidget(_CategoryPicker old) {
    super.didUpdateWidget(old);
    if (old.gameType != widget.gameType) _load();
    if (old.pendingSuggestionId != widget.pendingSuggestionId) {
      _loadSuggestion();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _cats = null;
    });
    try {
      final all = await PackRepository.instance.getCategories();
      if (mounted)
        setState(() {
          _cats = all;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSuggestion() async {
    final id = widget.pendingSuggestionId;
    if (id == null) {
      if (mounted) setState(() => _suggestion = null);
      return;
    }
    try {
      final row = await PackRepository.instance.getCategorySuggestion(id);
      if (mounted) setState(() => _suggestion = row);
    } catch (_) {
      // Best-effort status display only.
    }
  }

  Future<void> _showSuggestDialog() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.packSuggestNewCategory),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 60,
          decoration: InputDecoration(
            hintText: ctx.l10n.packCategoryHintExample,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(ctx.l10n.packSubmitForReview),
          ),
        ],
      ),
    );
    if (name == null || name.trim().length < 2) return;
    try {
      final id = await PackRepository.instance.suggestCategory(name.trim());
      widget.onSuggested?.call(id);
      if (mounted) {
        context.showSnackBar(context.l10n.packCategorySubmittedForReview);
      }
    } catch (e) {
      if (mounted)
        context.showErrorSnackBar(
          context.l10n.packFailedSuggestCategory(e.toString()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LinearProgressIndicator();
    final cats = _cats;

    if (widget.pendingSuggestionId != null) {
      final status = _suggestion?['status'] as String?;
      final name = _suggestion?['suggested_name'] as String? ?? '…';
      final reason = _suggestion?['rejection_reason'] as String?;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.packCategoryOptionalLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          if (status == 'rejected') ...[
            Text(
              reason != null && reason.isNotEmpty
                  ? context.l10n.packCategoryRejectedWithReason(name, reason)
                  : context.l10n.packCategoryRejectedNoReason(name),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => widget.onSelected(null),
                  child: Text(context.l10n.packPickExistingCategory),
                ),
                OutlinedButton(
                  onPressed: _showSuggestDialog,
                  child: Text(context.l10n.packSuggestAgain),
                ),
              ],
            ),
          ] else
            Chip(
              avatar: const Icon(Icons.hourglass_top, size: 16),
              label: Text(context.l10n.packPendingAdminReview(name)),
            ),
        ],
      );
    }

    if (cats == null || cats.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.packCategoryOptionalLabel,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            // None option
            ChoiceChip(
              label: Text(context.l10n.noneLabel),
              selected: widget.selectedId == null,
              onSelected: (_) => widget.onSelected(null),
            ),
            ...cats.map(
              (c) => ChoiceChip(
                avatar: Text(c.icon),
                label: Text(c.nameJson['en'] as String? ?? c.slug),
                selected: widget.selectedId == c.id,
                onSelected: (_) =>
                    widget.onSelected(widget.selectedId == c.id ? null : c.id),
              ),
            ),
            if (widget.onSuggested != null)
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: Text(context.l10n.packSuggestNew),
                onPressed: _showSuggestDialog,
              ),
          ],
        ),
      ],
    );
  }
}

// ── Step 2: Languages ────────────────────────────────────────────────────────
// Select every language the pack will be authored in before names/
// descriptions/cards, so _NamesStep can generate the right number of
// name/description fields and _CardsStep the right number of card-content
// fields.
class _LanguageStep extends StatefulWidget {
  const _LanguageStep({required this.draft, required this.onNext});
  final PackDraft draft;
  final VoidCallback onNext;

  @override
  State<_LanguageStep> createState() => _LanguageStepState();
}

class _LanguageStepState extends State<_LanguageStep> {
  // Fallback flags only — the *available* languages themselves always come
  // from the pack_languages table via _loadLanguages(), never hardcoded. A
  // code with no entry here just falls back to a generic flag emoji, it's
  // never excluded from the list.
  static const _flagEmoji = {
    'en': '🇬🇧',
    'ar': '🇸🇦',
    'fr': '🇫🇷',
    'es': '🇪🇸',
    'de': '🇩🇪',
    'pt': '🇵🇹',
    'tr': '🇹🇷',
    'ru': '🇷🇺',
  };

  List<(String, String)> _langs = [];

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    try {
      final langs = await PackRepository.instance.getAvailableLanguages();
      if (!mounted) return;
      setState(() {
        _langs = [
          for (final l in langs)
            (l.code, '${_flagEmoji[l.code] ?? '🏳️'} ${l.name}'),
        ];
      });
    } catch (_) {
      // Never block the form on this, and never silently fall back to a
      // fixed hardcoded set — just show whatever's already selected.
      if (mounted) {
        setState(() {
          _langs = [
            for (final code in widget.draft.selectedLanguages)
              (code, '${_flagEmoji[code] ?? '🏳️'} ${code.toUpperCase()}'),
          ];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final draft = widget.draft;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.packStepLanguages,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          Text(
            context.l10n.packSelectLanguagesHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ).animate(delay: 40.ms).fadeIn(),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final lang in _langs)
                FilterChip(
                  label: Text(lang.$2),
                  selected: draft.selectedLanguages.contains(lang.$1),
                  onSelected: (on) => setState(() {
                    if (on) {
                      if (!draft.selectedLanguages.contains(lang.$1)) {
                        draft.selectedLanguages.add(lang.$1);
                      }
                    } else if (draft.selectedLanguages.length > 1) {
                      // Must keep at least one language.
                      draft.selectedLanguages.remove(lang.$1);
                      draft.titles.remove(lang.$1);
                      draft.descriptions.remove(lang.$1);
                    }
                    // Set language field: 'multi' if >1, else single lang.
                    draft.language = draft.selectedLanguages.length > 1
                        ? 'multi'
                        : draft.selectedLanguages.first;
                  }),
                ),
            ],
          ).animate(delay: 60.ms).fadeIn(),
          const SizedBox(height: 32),
          JButton(
            label: context.l10n.continueArrow,
            onPressed: draft.selectedLanguages.isNotEmpty
                ? widget.onNext
                : null,
            icon: Icons.arrow_forward_rounded,
          ).animate(delay: 100.ms).fadeIn(),
        ],
      ),
    );
  }
}

// ── Step 1: General info (game type, category, price, spicy, min players,
// cover image) ───────────────────────────────────────────────────────────────
class _GeneralInfoStep extends StatefulWidget {
  const _GeneralInfoStep({required this.draft, required this.onNext});
  final PackDraft draft;
  final VoidCallback onNext;

  @override
  State<_GeneralInfoStep> createState() => _GeneralInfoStepState();
}

class _GeneralInfoStepState extends State<_GeneralInfoStep> {
  bool _isUploading = false;

  // Item 7: DB-driven situation-tag vocabulary (see PackSituationTagPicker)
  // — loaded once per step, same as every other admin-configurable list
  // this screen already fetches (languages, categories).
  List<PackSituationTag> _situationTags = [];

  @override
  void initState() {
    super.initState();
    _loadSituationTags();
  }

  Future<void> _loadSituationTags() async {
    try {
      final tags = await PackRepository.instance.getSituationFilters();
      if (mounted) setState(() => _situationTags = tags);
    } catch (_) {
      // Best-effort — an empty picker just means no tags to pick this
      // session, never blocks pack creation.
    }
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await PackUploadService.instance.uploadCoverImage(
        File(picked.path),
      );
      setState(() {
        widget.draft.coverImagePath = picked.path;
        widget.draft.coverImageUrl = url;
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted)
        context.showErrorSnackBar(context.l10n.packUploadFailed(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final draft = widget.draft;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.packInformationTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 24),

          // Game type
          DropdownButtonFormField<String>(
            initialValue: draft.gameType,
            decoration: InputDecoration(
              labelText: context.l10n.packGameTypeLabel,
            ),
            items: [
              DropdownMenuItem(
                value: 'truth_or_dare',
                child: Text(context.l10n.packGameTypeTod),
              ),
              DropdownMenuItem(
                value: 'never_have_i_ever',
                child: Text(context.l10n.packGameTypeNhie),
              ),
              DropdownMenuItem(
                value: 'meme_game',
                child: Text(context.l10n.packGameTypeMeme),
              ),
            ],
            onChanged: (v) => setState(() {
              draft.gameType = v ?? 'truth_or_dare';
              draft.categoryId = null; // reset category when game changes
            }),
          ).animate(delay: 60.ms).fadeIn(),

          const SizedBox(height: 16),

          // Category picker
          _CategoryPicker(
            gameType: draft.gameType,
            selectedId: draft.categoryId,
            pendingSuggestionId: draft.pendingCategorySuggestionId,
            onSelected: (id) => setState(() {
              draft.categoryId = id;
              draft.pendingCategorySuggestionId = null;
            }),
            onSuggested: (id) => setState(() {
              draft.categoryId = null;
              draft.pendingCategorySuggestionId = id;
            }),
          ).animate(delay: 80.ms).fadeIn(),

          const SizedBox(height: 16),

          // Optional situation types (item 6) — stored via the existing
          // pack_tags table/draft.tags plumbing, already sent to the
          // backend on create/update; entirely optional, a pack with none
          // selected creates exactly as it always has.
          PackSituationTagPicker(
            title: context.l10n.packCreationTagsTitle,
            subtitle: context.l10n.packCreationTagsSubtitle,
            tags: _situationTags,
            selected: draft.tags.toSet(),
            onToggle: (slug) => setState(() {
              if (draft.tags.contains(slug)) {
                draft.tags = draft.tags.where((t) => t != slug).toList();
              } else {
                draft.tags = [...draft.tags, slug];
              }
            }),
          ).animate(delay: 90.ms).fadeIn(),

          const SizedBox(height: 16),

          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: draft.priceMru.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.l10n.packPriceLabel,
                    hintText: context.l10n.packMinPriceLabel(
                      AppConstants.minPaidPackPriceMru,
                    ),
                    suffixText: context.l10n.walletCurrencyShort,
                    // draft.priceMru drove both this errorText and the
                    // Continue button's onPressed below — mutating it
                    // without setState (the old behavior) meant neither
                    // ever updated as the user typed, same underlying bug
                    // class as the Names step (see _NamesStepState).
                    errorText: draft.hasValidPrice
                        ? null
                        : context.l10n.packMinPriceError(
                            AppConstants.minPaidPackPriceMru,
                          ),
                  ),
                  onChanged: (v) =>
                      setState(() => draft.priceMru = int.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              // Client-side mirror of the server-side gate now enforced
              // inside submit_pack_for_review() (raises
              // spicy_content_disabled) — hiding the toggle here is UX
              // only, not the source of truth.
              if (context.watch<PlatformConfigProvider>().spicyContentEnabled)
                Row(
                  children: [
                    Text(
                      context.l10n.packSpicyLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: draft.allowSpicy,
                      onChanged: (v) => setState(() => draft.allowSpicy = v),
                    ),
                  ],
                ),
            ],
          ).animate(delay: 100.ms).fadeIn(),

          const SizedBox(height: 16),

          // Min players
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.packMinPlayersLabel(draft.minPlayers),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.packWhoCanPlay,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Slider(
                value: draft.minPlayers.toDouble(),
                min: 2,
                max: 10,
                divisions: 8,
                label: context.l10n.packPlayersSliderLabel(draft.minPlayers),
                onChanged: (v) => setState(() {
                  draft.minPlayers = v.round();
                  // Keep maxPlayers a valid upper bound (>= minPlayers) as
                  // the creator drags minPlayers past it, rather than
                  // letting the draft enter a silently-invalid state that
                  // only surfaces later at the issues screen.
                  if (draft.maxPlayers != null &&
                      draft.maxPlayers! < draft.minPlayers) {
                    draft.maxPlayers = draft.minPlayers;
                  }
                }),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    context.l10n.packSetMaxPlayersToggle,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Switch(
                    value: draft.maxPlayers != null,
                    onChanged: (v) => setState(() {
                      // Explicitly optional: turning the toggle off always
                      // clears back to null (no limit), never to 0 — a
                      // creator who never touches this control leaves an
                      // unplayable-looking pack.
                      draft.maxPlayers = v ? draft.minPlayers : null;
                    }),
                  ),
                ],
              ),
              if (draft.maxPlayers != null) ...[
                Text(
                  context.l10n.packMaxPlayersLabel(draft.maxPlayers!),
                  style: theme.textTheme.bodyMedium,
                ),
                Slider(
                  value: draft.maxPlayers!.toDouble(),
                  min: draft.minPlayers.toDouble(),
                  max: 12,
                  divisions: (12 - draft.minPlayers).clamp(1, 12),
                  label: context.l10n.packMaxPlayersSliderLabel(
                    draft.maxPlayers!,
                  ),
                  onChanged: (v) =>
                      setState(() => draft.maxPlayers = v.round()),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    context.l10n.packNoMaxPlayersHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ).animate(delay: 110.ms).fadeIn(),

          const SizedBox(height: 24),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),

          Text(
            context.l10n.packCoverImageLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ).animate(delay: 115.ms).fadeIn(),
          const SizedBox(height: 4),
          Text(
            context.l10n.packCoverImageHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ).animate(delay: 115.ms).fadeIn(),
          const SizedBox(height: 16),
          Center(
            child:
                GestureDetector(
                      onTap: _isUploading ? null : _pickAndUpload,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.outline,
                            width: 2,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                        ),
                        child: _isUploading
                            ? const Center(child: CircularProgressIndicator())
                            : draft.coverImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.file(
                                  File(draft.coverImagePath!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            // Reopened draft: the local file path is gone but the
                            // uploaded cover URL was persisted — show it instead of
                            // the "add cover" placeholder.
                            : draft.coverImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: SignedNetworkImage(
                                  url: draft.coverImageUrl!,
                                  fit: BoxFit.cover,
                                  width: 220,
                                  height: 220,
                                  errorBuilder: (_) => const Center(
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 48,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.l10n.packTapToAddCover,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    )
                    .animate(delay: 120.ms)
                    .fadeIn()
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                    ),
          ),

          const SizedBox(height: 24),

          // Item 17.1/17.2 — live in-game card preview. Resolves its
          // background through the exact same GameCardBackground the real
          // game screens use (pack cover -> jma3a_card_cover_playful.png
          // -> flat color), so this preview and the actual card players
          // see can never silently diverge. Updates immediately as
          // draft.coverImageUrl changes — no save/reload needed, since
          // this whole step already rebuilds via setState on upload.
          Text(
            context.l10n.packLivePreviewLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ).animate(delay: 125.ms).fadeIn(),
          const SizedBox(height: 4),
          Text(
            context.l10n.packLivePreviewHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ).animate(delay: 125.ms).fadeIn(),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 200,
              height: 266,
              child: GameCardPreview(
                gameType: draft.gameType,
                content: context.l10n.packCardPreviewSampleText,
                imageUrl: draft.coverImageUrl,
              ),
            ),
          ).animate(delay: 135.ms).fadeIn(),

          const SizedBox(height: 32),

          JButton(
            label: context.l10n.continueArrow,
            // CORRECTION PASS §3: cover image is optional — PackDraft.
            // validationIssues() (the single authoritative validation,
            // see its own doc comment) never required one; this button
            // was a second, stricter, undocumented gate that disagreed
            // with it. A missing cover falls back to the shared default
            // (GameCardBackground's jma3a_card_cover_playful.png chain)
            // everywhere the cover is later rendered.
            onPressed: draft.hasValidPrice ? widget.onNext : null,
            icon: Icons.arrow_forward_rounded,
          ).animate(delay: 140.ms).fadeIn(),
        ],
      ),
    );
  }
}

// ── Step 3: Names & descriptions ────────────────────────────────────────────
class _NamesStep extends StatefulWidget {
  const _NamesStep({required this.draft, required this.onNext});
  final PackDraft draft;
  final VoidCallback onNext;

  @override
  State<_NamesStep> createState() => _NamesStepState();
}

class _NamesStepState extends State<_NamesStep> {
  late final Map<String, TextEditingController> _titleCtrls;
  late final Map<String, TextEditingController> _descCtrls;

  String _langLabel(BuildContext context, String code) => switch (code) {
    'en' => context.l10n.packLangEnglish,
    'ar' => context.l10n.packLangArabic,
    'fr' => context.l10n.packLangFrench,
    'es' => context.l10n.packLangSpanish,
    'de' => context.l10n.packLangGerman,
    'pt' => context.l10n.packLangPortuguese,
    'tr' => context.l10n.packLangTurkish,
    'ru' => context.l10n.packLangRussian,
    _ => code.toUpperCase(),
  };

  @override
  void initState() {
    super.initState();
    // A fresh _NamesStepState is created every time _step changes (the
    // AnimatedSwitcher above is keyed on _step), so this always reflects
    // whatever selectedLanguages the Language step left behind — no need
    // to react to changes after the fact.
    _titleCtrls = {
      for (final lang in widget.draft.selectedLanguages)
        lang: TextEditingController(text: widget.draft.titles[lang] ?? ''),
    };
    _descCtrls = {
      for (final lang in widget.draft.selectedLanguages)
        lang: TextEditingController(
          text: widget.draft.descriptions[lang] ?? '',
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _titleCtrls.values) {
      c.dispose();
    }
    for (final c in _descCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final draft = widget.draft;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.packStepNamesDescriptions,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          Text(
            context.l10n.packOneNamePerLanguage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ).animate(delay: 40.ms).fadeIn(),
          const SizedBox(height: 24),

          for (final lang in draft.selectedLanguages) ...[
            TextFormField(
              controller: _titleCtrls[lang],
              // draft.titles is a plain mutable map on a plain Dart object
              // (PackDraft is not a ChangeNotifier) — mutating it alone
              // doesn't rebuild anything. setState is what makes the
              // Continue button below re-evaluate draft.hasTitle on every
              // keystroke instead of only once, at the initial (empty)
              // build — that gap was the actual bug: the condition itself
              // was always correct, it just never got re-checked as the
              // user typed, so the button stayed permanently disabled.
              onChanged: (v) => setState(() => draft.titles[lang] = v),
              decoration: InputDecoration(
                labelText: context.l10n.packNameFieldLabel(
                  _langLabel(context, lang),
                ),
                hintText: context.l10n.packNameHint,
              ),
              textCapitalization: TextCapitalization.words,
            ).animate(delay: 60.ms).fadeIn(),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrls[lang],
              onChanged: (v) => setState(() => draft.descriptions[lang] = v),
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: context.l10n.packDescriptionFieldLabel(
                  _langLabel(context, lang),
                ),
                counterText: '',
              ),
            ).animate(delay: 80.ms).fadeIn(),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 16),

          JButton(
            label: context.l10n.continueArrow,
            onPressed: draft.hasTitle ? widget.onNext : null,
            icon: Icons.arrow_forward_rounded,
          ).animate(delay: 120.ms).fadeIn(),
        ],
      ),
    );
  }
}

// ── Step 4: Audience restrictions ───────────────────────────────────────────
class _AudienceStep extends StatefulWidget {
  const _AudienceStep({required this.draft, required this.onNext});
  final PackDraft draft;
  final VoidCallback onNext;

  @override
  State<_AudienceStep> createState() => _AudienceStepState();
}

class _AudienceStepState extends State<_AudienceStep> {
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final draft = widget.draft;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.packStepAudience,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          Text(
            context.l10n.packAudienceHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ).animate(delay: 40.ms).fadeIn(),
          const SizedBox(height: 24),

          Text(
            context.l10n.packAgeLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ).animate(delay: 60.ms).fadeIn(),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in <(String, int?, int?)>[
                (context.l10n.packAudienceEveryone, null, null),
                ('18+', 18, null),
                ('21+', 21, null),
              ])
                ChoiceChip(
                  label: Text(option.$1),
                  selected:
                      draft.minAge == option.$2 && draft.maxAge == option.$3,
                  onSelected: (_) => setState(() {
                    draft.minAge = option.$2;
                    draft.maxAge = option.$3;
                  }),
                ),
            ],
          ).animate(delay: 80.ms).fadeIn(),
          const SizedBox(height: 24),

          Text(
            context.l10n.packGenderLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in <(String, String)>[
                (context.l10n.packAudienceEveryone, 'everyone'),
                (context.l10n.packGenderMaleOnly, 'male'),
                (context.l10n.packGenderFemaleOnly, 'female'),
              ])
                ChoiceChip(
                  label: Text(option.$1),
                  selected: draft.genderRestriction == option.$2,
                  onSelected: (_) =>
                      setState(() => draft.genderRestriction = option.$2),
                ),
            ],
          ).animate(delay: 120.ms).fadeIn(),

          const SizedBox(height: 32),

          JButton(
            label: context.l10n.continueArrow,
            onPressed: widget.onNext,
            icon: Icons.arrow_forward_rounded,
          ).animate(delay: 140.ms).fadeIn(),
        ],
      ),
    );
  }
}

// ── Step 5: Cards ─────────────────────────────────────────────────────────────

String _cardTypeEmoji(CardType t) => switch (t) {
  CardType.truth => '🤔',
  CardType.dare => '🔥',
  CardType.statement => '🍹',
  CardType.prompt => '😂',
};

String _gameTypeName(BuildContext context, String gameType) =>
    switch (gameType) {
      'never_have_i_ever' => context.l10n.gameNameNeverHaveIEver,
      'meme_game' => context.l10n.gameNameMeme,
      _ => context.l10n.gameNameTruthOrDare,
    };

String _difficultyLabel(BuildContext context, CardDifficulty d) => switch (d) {
  CardDifficulty.mild => context.l10n.packDifficultyMild,
  CardDifficulty.medium => context.l10n.packDifficultyMedium,
  CardDifficulty.spicy => context.l10n.packDifficultySpicy,
};

String _cardTypeLabel(BuildContext context, CardType t) => switch (t) {
  CardType.truth => context.l10n.todTruth,
  CardType.dare => context.l10n.todDare,
  CardType.statement => context.l10n.packCardTypeStatement,
  CardType.prompt => context.l10n.packCardTypePrompt,
};

Color _cardTypeColor(CardType t) => switch (t) {
  CardType.truth => AppColors.truthColor,
  CardType.dare => AppColors.dareColor,
  CardType.statement => AppColors.tealGreen,
  CardType.prompt => AppColors.purple,
};

class _CardsStep extends StatefulWidget {
  const _CardsStep({
    required this.draft,
    required this.packId,
    required this.onNext,
    required this.onBack,
  });
  final PackDraft draft;
  final String? packId;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<_CardsStep> createState() => _CardsStepState();
}

class _CardsStepState extends State<_CardsStep> {
  late CardType _type;
  CardDifficulty _difficulty = CardDifficulty.mild;
  bool _isSaving = false;

  // Item 17.6 — the text currently being typed for a NEW card, before
  // "Add" is pressed. Purely local UI state for the live compose preview
  // below; never touches widget.draft.cards until _MultiLangCardInput's
  // own onAdd fires (unchanged persistence path).
  String _liveText = '';

  @override
  void initState() {
    super.initState();
    // Set default card type based on game type
    _type = _defaultTypeForGame(widget.draft.gameType);
  }

  CardType _defaultTypeForGame(String gameType) {
    switch (gameType) {
      case 'never_have_i_ever':
        return CardType.statement;
      case 'meme_game':
        return CardType.prompt;
      default:
        return CardType.truth; // truth_or_dare
    }
  }

  List<(CardType, String, Color)> _typesForGame(
    BuildContext context,
    String gameType,
  ) {
    switch (gameType) {
      case 'never_have_i_ever':
        return [
          (
            CardType.statement,
            context.l10n.packTypeStatement,
            AppColors.tealGreen,
          ),
        ];
      case 'meme_game':
        return [
          (CardType.prompt, context.l10n.packTypePrompt, AppColors.purple),
        ];
      default:
        return [
          (CardType.truth, context.l10n.packTypeTruth, AppColors.truthColor),
          (CardType.dare, context.l10n.packTypeDare, AppColors.dareColor),
        ];
    }
  }

  Future<void> _saveAndContinue() async {
    if (widget.packId == null) return;
    if (widget.draft.cards.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await PackRepository.instance.addCards(
        widget.packId!,
        widget.draft.cards,
      );
      widget.onNext();
    } catch (e) {
      if (mounted)
        context.showErrorSnackBar(
          context.l10n.packFailedToSaveCards(e.toString()),
        );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cards = widget.draft.cards;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [_cardsStepScrollBody(context, theme, cards)],
            ),
          ),
        ),

        // Bottom bar — pinned outside the scroll view.
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  child: Text(context.l10n.back),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: JButton(
                  label: context.l10n.continueArrow,
                  onPressed: cards.length >= 20 ? _saveAndContinue : null,
                  isLoading: _isSaving,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Everything that used to be the whole build() body except the pinned
  // bottom bar — extracted so it can live inside a SingleChildScrollView
  // (item 17.9: the previous unbounded Expanded card-management list plus
  // the new preview sections would otherwise overflow on small phones).
  Widget _cardsStepScrollBody(
    BuildContext context,
    ThemeData theme,
    List<CardDraft> cards,
  ) {
    return Column(
      children: [
        // Card input area
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${cards.length} / 20+ cards',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    cards.length < 20
                        ? '${20 - cards.length} more needed'
                        : '✅ Minimum reached',
                    style: TextStyle(
                      fontSize: 12,
                      color: cards.length >= 20
                          ? AppColors.successGreen
                          : AppColors.warningAmber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // Truth or Dare packs must end with an equal number of each type.
              // Communicated live here (not just at submit) so the creator can
              // balance as they go. Only shown for truth_or_dare.
              if (widget.draft.isTruthOrDare) ...[
                const SizedBox(height: 6),
                Text(
                  context.l10n.packTruthDareBalanceHint(
                    widget.draft.truthCount,
                    widget.draft.dareCount,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.draft.hasBalancedTruthDare
                        ? AppColors.successGreen
                        : AppColors.warningAmber,
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // Type + difficulty selectors — adapts to game type
              Row(
                children: [
                  ..._typesForGame(context, widget.draft.gameType).map((t) {
                    final (type, label, color) = t;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _TypeButton(
                        label: label,
                        isSelected: _type == type,
                        color: color,
                        onTap: () => setState(() => _type = type),
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  DropdownButton<CardDifficulty>(
                    value: _difficulty,
                    underline: const SizedBox.shrink(),
                    items: CardDifficulty.values
                        .where(
                          (d) =>
                              d != CardDifficulty.spicy ||
                              widget.draft.allowSpicy,
                        )
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(_difficultyLabel(context, d)),
                          ),
                        )
                        .toList(),
                    onChanged: (d) => setState(() => _difficulty = d!),
                  ),
                  if (!widget.draft.allowSpicy)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Tooltip(
                        message: context.l10n.packEnableSpicyHint,
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Multi-language card input — show field per selected language
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _MultiLangCardInput(
                      draft: widget.draft,
                      onAdd: (CardDraft card) => setState(() {
                        widget.draft.cards.add(card);
                        _liveText = '';
                      }),
                      type: _type,
                      difficulty: _difficulty,
                      onPrimaryTextChanged: (text) =>
                          setState(() => _liveText = text),
                    ),
                  ),
                  if (_liveText.trim().isNotEmpty) ...[
                    const SizedBox(width: 12),
                    // Item 17.6 — live preview of the card currently being
                    // typed, before "Add" is pressed. Purely visual;
                    // widget.draft.cards is untouched until onAdd fires.
                    SizedBox(
                      width: 110,
                      height: 146,
                      child: GameCardPreview(
                        gameType: widget.draft.gameType,
                        content: _liveText,
                        cardTypeIsDare: _type == CardType.dare,
                        isSpicy: _difficulty == CardDifficulty.spicy,
                        imageUrl: widget.draft.coverImageUrl,
                      ),
                    ).animate().fadeIn(duration: 150.ms),
                  ],
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Item 17.3-17.6 — swipeable, in-game-styled preview of every card
        // already added, in the same order as widget.draft.cards (never
        // reordered by browsing it). Purely visual: PageView's own index
        // is local State, never written back into the draft.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.packCardPreviewSectionLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _CardPreviewSwiper(
                cards: cards,
                gameType: widget.draft.gameType,
                primaryLanguage: widget.draft.selectedLanguages.isNotEmpty
                    ? widget.draft.selectedLanguages.first
                    : 'en',
                packCoverUrl: widget.draft.coverImageUrl,
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Card management list — unchanged deletion behavior, now
        // shrink-wrapped so it contributes its natural height to the
        // outer SingleChildScrollView instead of requiring its own
        // Expanded (which an unbounded scroll ancestor can't give it).
        Padding(
          padding: const EdgeInsets.all(12),
          child: cards.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text(context.l10n.packAddFirstCardHint)),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cards.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final card = cards[i];
                    final color = _cardTypeColor(card.type);
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _cardTypeEmoji(card.type),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _cardTypeLabel(context, card.type),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              // Preview in the primary selected language (not a
                              // hardcoded 'en', which would be blank for e.g. a
                              // Hassaniya-only pack); fall back to any content.
                              card.content[widget
                                      .draft
                                      .selectedLanguages
                                      .first] ??
                                  (card.content.values.isNotEmpty
                                      ? card.content.values.first
                                      : ''),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () => setState(() => cards.removeAt(i)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ).animate(delay: (i * 15).ms).fadeIn();
                  },
                ),
        ),
      ],
    );
  }
}

// ── Multi-language card input ──────────────────────────────────────────────────
class _MultiLangCardInput extends StatefulWidget {
  const _MultiLangCardInput({
    required this.draft,
    required this.onAdd,
    required this.type,
    required this.difficulty,
    this.onPrimaryTextChanged,
  });
  final PackDraft draft;
  final void Function(CardDraft) onAdd;
  final CardType type;
  final CardDifficulty difficulty;

  /// Item 17.6 — reports the PRIMARY selected language's in-progress text
  /// on every keystroke, purely so the caller can drive a live "what
  /// you're typing" preview. Never read back here, never persisted.
  final ValueChanged<String>? onPrimaryTextChanged;
  @override
  State<_MultiLangCardInput> createState() => _MultiLangCardInputState();
}

class _MultiLangCardInputState extends State<_MultiLangCardInput> {
  // One controller per language CODE, created lazily so any dynamic language
  // the server offers (e.g. 'hs' Hassaniya) gets its own input — not just a
  // fixed en/ar/fr trio.
  final Map<String, TextEditingController> _ctrls = {};

  TextEditingController _ctrlFor(String lang) =>
      _ctrls.putIfAbsent(lang, () => TextEditingController());

  // Item 3 — meme sticker library. Only offered for prompt (meme) cards;
  // every other card type is unaffected. Selecting a library sticker here
  // just sets these two fields on the CardDraft constructed in _add() —
  // the pack-owned upload flow (CardDraft.imageUrl) is untouched and
  // remains available for a future upload entry point.
  String? _stickerId;
  String? _stickerUrl;

  Future<void> _pickSticker() async {
    final selected = await showModalBottomSheet<StickerEntity>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _StickerPickerSheet(),
    );
    if (selected != null && mounted) {
      setState(() {
        _stickerId = selected.id;
        _stickerUrl = selected.publicUrl;
      });
    }
  }

  // Static labels/hints for the well-known languages; anything else falls back
  // to the uppercased code, so the field still renders and works.
  static const _langLabels = {
    'en': '🇬🇧 EN',
    'ar': '🇸🇦 AR',
    'fr': '🇫🇷 FR',
  };
  // Languages written in Arabic script render right-to-left (Hassaniya too).
  bool _isRtl(String lang) => lang == 'ar' || lang == 'hs';

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _add() {
    final langs = widget.draft.selectedLanguages;
    // Validate all selected languages have content — dynamically, per code.
    final missing = langs
        .where((l) => _ctrlFor(l).text.trim().isEmpty)
        .toList();
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.packFillContentInLanguages(missing.join(', ')),
          ),
        ),
      );
      return;
    }
    final card = CardDraft(type: widget.type, difficulty: widget.difficulty);
    for (final l in langs) {
      card.setContent(l, _ctrlFor(l).text.trim());
    }
    card.stickerId = _stickerId;
    widget.onAdd(card);
    for (final c in _ctrls.values) {
      c.clear();
    }
    widget.onPrimaryTextChanged?.call('');
    setState(() {
      _stickerId = null;
      _stickerUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final langs = widget.draft.selectedLanguages;
    return Column(
      children: [
        for (final lang in langs) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 44,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      _langLabels[lang] ?? lang.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _ctrlFor(lang),
                  maxLines: 2,
                  textDirection: _isRtl(lang)
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: _isRtl(lang)
                        ? 'محتوى البطاقة…'
                        : lang == 'fr'
                        ? 'Contenu de la carte…'
                        : 'Card content…',
                    isDense: true,
                  ),
                  onChanged: lang == langs.first
                      ? widget.onPrimaryTextChanged
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        if (widget.type == CardType.prompt)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickSticker,
                  icon: _stickerUrl != null
                      ? ClipOval(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: SignedNetworkImage(
                              url: _stickerUrl!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : const Icon(Icons.emoji_emotions_outlined, size: 18),
                  label: Text(
                    _stickerId != null
                        ? context.l10n.packStickerSelected
                        : context.l10n.packChooseSticker,
                  ),
                ),
                if (_stickerId != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: context.l10n.packRemoveSticker,
                    onPressed: () => setState(() {
                      _stickerId = null;
                      _stickerUrl = null;
                    }),
                  ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton.filled(
            onPressed: _add,
            icon: const Icon(Icons.add_rounded),
            style: IconButton.styleFrom(backgroundColor: AppColors.navyBlue),
          ),
        ),
      ],
    );
  }
}

/// Item 3 — browses the centralized sticker library
/// (PackRepository.getStickerLibrary) for _MultiLangCardInput's sticker
/// picker button. Pops the chosen StickerEntity, or null if dismissed.
class _StickerPickerSheet extends StatefulWidget {
  const _StickerPickerSheet();

  @override
  State<_StickerPickerSheet> createState() => _StickerPickerSheetState();
}

class _StickerPickerSheetState extends State<_StickerPickerSheet> {
  List<StickerEntity>? _stickers;

  @override
  void initState() {
    super.initState();
    PackRepository.instance
        .getStickerLibrary()
        .then((s) {
          if (mounted) setState(() => _stickers = s);
        })
        .catchError((_) {
          if (mounted) setState(() => _stickers = const []);
        });
  }

  @override
  Widget build(BuildContext context) {
    final stickers = _stickers;
    return SafeArea(
      child: SizedBox(
        height: 420,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                context.l10n.packChooseSticker,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: stickers == null
                  ? const Center(child: CircularProgressIndicator())
                  : stickers.isEmpty
                  ? Center(child: Text(context.l10n.packNoStickersAvailable))
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                      itemCount: stickers.length,
                      itemBuilder: (context, i) {
                        final s = stickers[i];
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.of(context).pop(s),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SignedNetworkImage(
                              url: s.publicUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_) =>
                                  const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item 17.3-17.6/17.9/17.10 — Tinder-style, sequential (never cyclic)
/// browsing of every card already added, in [cards]' own order. Purely a
/// viewing aid: [_index] is local State only, never written back into
/// [cards] or the draft — swiping can never reorder/mutate/delete a card.
///
/// Uses a plain PageView (no third-party swiper package exists in this
/// project — see pubspec.yaml) with a lightweight AnimatedBuilder-driven
/// scale/rotate transform on top, matching the "slightly rotate, scale,
/// reveal next card underneath" feel item 17.5 asks for while staying on
/// Flutter's own native, performant pagination/fling handling — no custom
/// gesture/physics code, and it can never intercept text-field or
/// scroll/delete gestures elsewhere on the screen since it only owns
/// input within its own bounded SizedBox.
class _CardPreviewSwiper extends StatefulWidget {
  const _CardPreviewSwiper({
    required this.cards,
    required this.gameType,
    required this.primaryLanguage,
    required this.packCoverUrl,
  });
  final List<CardDraft> cards;
  final String gameType;
  final String primaryLanguage;
  final String? packCoverUrl;

  @override
  State<_CardPreviewSwiper> createState() => _CardPreviewSwiperState();
}

class _CardPreviewSwiperState extends State<_CardPreviewSwiper> {
  late final PageController _controller = PageController(viewportFraction: 0.8);
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CardPreviewSwiper old) {
    super.didUpdateWidget(old);
    // A card was deleted (or the list changed) and the current index no
    // longer points at anything — clamp back onto the last remaining
    // card instead of showing a blank page. Never touches widget.cards.
    if (widget.cards.isNotEmpty && _index >= widget.cards.length) {
      final next = widget.cards.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _index = next);
        if (_controller.hasClients) _controller.jumpToPage(next);
      });
    }
  }

  String _textFor(BuildContext context, CardDraft card) {
    final text =
        card.content[widget.primaryLanguage] ??
        (card.content.values.isNotEmpty ? card.content.values.first : '');
    return text.isEmpty ? context.l10n.packCardPreviewSampleText : text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.cards.isEmpty) {
      return Container(
        height: 240,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎴', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                context.l10n.packCardPreviewEmptyTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.packCardPreviewEmptyBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.cards.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final card = widget.cards[i];
              final preview = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: GameCardPreview(
                  key: ValueKey(card.id ?? identityHashCode(card)),
                  gameType: widget.gameType,
                  content: _textFor(context, card),
                  cardTypeIsDare: card.type == CardType.dare,
                  isSpicy: card.difficulty == CardDifficulty.spicy,
                  imageUrl: card.imageUrl ?? widget.packCoverUrl,
                ),
              );
              return AnimatedBuilder(
                animation: _controller,
                child: preview,
                builder: (context, child) {
                  var page = _index.toDouble();
                  if (_controller.hasClients &&
                      _controller.position.haveDimensions) {
                    page = _controller.page ?? _index.toDouble();
                  }
                  final delta = (page - i).clamp(-1.0, 1.0);
                  final scale = 1 - delta.abs() * 0.14;
                  final angle = delta * -0.10;
                  return Transform.scale(
                    scale: scale,
                    child: Transform.rotate(angle: angle, child: child),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.packCardPreviewCountLabel(
            _index + 1,
            widget.cards.length,
          ),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Step 6 (Truth or Dare only): Punishments ────────────────────────────────
// Mirrors _CardsStep's layout deliberately (input area with a live counter,
// scrollable list of added items, fixed Back/Continue bar) so this feels
// like the same kind of "add multiple things" flow the creator just used
// for cards. Completely optional — the only constraint is >=10 if any are
// added, matching packs_suggested_punishments_check server-side.
class _PunishmentsStep extends StatefulWidget {
  const _PunishmentsStep({
    required this.draft,
    required this.onNext,
    required this.onBack,
  });
  final PackDraft draft;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<_PunishmentsStep> createState() => _PunishmentsStepState();
}

class _PunishmentsStepState extends State<_PunishmentsStep> {
  final _inputCtrl = TextEditingController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  void _add() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.draft.suggestedPunishments.add(text);
      _inputCtrl.clear();
    });
  }

  Future<void> _edit(int index) async {
    final ctrl = TextEditingController(
      text: widget.draft.suggestedPunishments[index],
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.packEditPunishment),
        content: TextField(controller: ctrl, autofocus: true, maxLines: 2),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(ctx.l10n.save),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      setState(() => widget.draft.suggestedPunishments[index] = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final punishments = widget.draft.suggestedPunishments;
    final canContinue = punishments.isEmpty || punishments.length >= 10;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.packPunishmentsOptionalTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.packPunishmentsHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    context.l10n.packPunishmentCount(punishments.length),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (punishments.isNotEmpty)
                    Text(
                      punishments.length >= 10
                          ? context.l10n.packMinimumReached
                          : context.l10n.packMoreNeeded(
                              10 - punishments.length,
                            ),
                      style: TextStyle(
                        fontSize: 12,
                        color: punishments.length >= 10
                            ? AppColors.successGreen
                            : AppColors.warningAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _inputCtrl,
                      decoration: InputDecoration(
                        labelText: context.l10n.packPunishmentInputHint,
                      ),
                      onFieldSubmitted: (_) => _add(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _add,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        Expanded(
          child: punishments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      context.l10n.packPunishmentsEmptyHint,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: punishments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    return Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: const Text(
                          '🎯',
                          style: TextStyle(fontSize: 16),
                        ),
                        title: Text(punishments[i]),
                        onTap: () => _edit(i),
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () =>
                              setState(() => punishments.removeAt(i)),
                        ),
                      ),
                    ).animate(delay: (i * 15).ms).fadeIn();
                  },
                ),
        ),

        if (punishments.isNotEmpty && punishments.length < 10)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              context.l10n.packAddMoreMinimum(10 - punishments.length),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  child: Text(context.l10n.back),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: JButton(
                  label: context.l10n.continueArrow,
                  onPressed: canContinue ? widget.onNext : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Step 6 (Meme only): Reactions ─────────────────────────────────────────────
class _ReactionsStep extends StatefulWidget {
  const _ReactionsStep({
    required this.draft,
    required this.packId,
    required this.onNext,
    required this.onBack,
  });
  final PackDraft draft;
  final String? packId;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<_ReactionsStep> createState() => _ReactionsStepState();
}

class _ReactionsStepState extends State<_ReactionsStep> {
  bool _isSaving = false;

  Future<void> _pickAndUpload() async {
    if (widget.draft.reactionImageUrls.length >= 30) {
      context.showErrorSnackBar(context.l10n.packMaxReactionImagesReached);
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty || !mounted) return;

    final remaining = 30 - widget.draft.reactionImageUrls.length;
    final toUpload = picked.take(remaining).toList();

    setState(() => _isSaving = true);
    try {
      for (final xfile in toUpload) {
        final file = File(xfile.path);
        final url = await PackUploadService.instance.uploadCardImage(file);
        setState(() => widget.draft.reactionImageUrls.add(url));
      }
    } catch (e) {
      if (mounted)
        context.showErrorSnackBar(context.l10n.packUploadFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveAndContinue() async {
    if (widget.packId == null) {
      widget.onNext();
      return;
    }
    setState(() => _isSaving = true);
    try {
      await PackRepository.instance.savePackReactions(
        widget.packId!,
        widget.draft.reactionImageUrls,
      );
      widget.onNext();
    } catch (e) {
      if (mounted)
        context.showErrorSnackBar(
          context.l10n.packFailedToSaveReactions(e.toString()),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final reactions = widget.draft.reactionImageUrls;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.l10n.packReactionImageCount(reactions.length),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    reactions.isEmpty
                        ? context.l10n.packReactionsOptionalHint
                        : context.l10n.packReactionSlotsRemaining(
                            30 - reactions.length,
                          ),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.packReactionsDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: reactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.packNoReactionImagesYet,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: reactions.length,
                  itemBuilder: (_, i) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            reactions[i],
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => setState(() => reactions.removeAt(i)),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (reactions.length < 30)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickAndUpload,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_photo_alternate_rounded),
                    label: Text(
                      _isSaving
                          ? context.l10n.packUploadingEllipsis
                          : context.l10n.packAddImages,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onBack,
                      child: Text(context.l10n.back),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving ? null : _saveAndContinue,
                      child: Text(
                        reactions.isEmpty
                            ? context.l10n.skip
                            : context.l10n.continueLabel,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Step 7: Publish ────────────────────────────────────────────────────────────
class _PublishStep extends StatefulWidget {
  const _PublishStep({
    required this.draft,
    required this.packId,
    required this.isSaving,
    required this.onPublish,
    required this.onBack,
  });
  final PackDraft draft;
  final String? packId;
  final bool isSaving;
  final VoidCallback onPublish;
  final VoidCallback onBack;

  @override
  State<_PublishStep> createState() => _PublishStepState();
}

class _PublishStepState extends State<_PublishStep> {
  PackCreationStatus? _status;
  bool _loadingStatus = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await PackRepository.instance.getPackCreationStatus();
      if (mounted) setState(() {
        _status = status;
        _loadingStatus = false;
      });
    } catch (_) {
      // Read-only preflight — a failure here just means the eligibility
      // card falls back to a neutral "we'll confirm when you submit"
      // state; submitForReview() is still the real, authoritative check.
      if (mounted) setState(() => _loadingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final draft = widget.draft;
    // THE authoritative gate — same PackDraft.validationIssues() the model and
    // (server-side) submit both use, so the button state and the reasons shown
    // can never disagree. Never a silent disable.
    final issues = draft.validationIssues();
    final canPublish = issues.isEmpty && widget.packId != null;
    final titleValue = draft.selectedLanguages.isNotEmpty
        ? (draft.titles[draft.selectedLanguages.first] ?? '')
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.packReadyToPublish,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          Text(
            context.l10n.packReviewBeforeSubmitting,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ).animate(delay: 40.ms).fadeIn(),

          const SizedBox(height: 24),

          // Summary card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryRow(
                  label: context.l10n.packSummaryTitle,
                  value: titleValue,
                  icon: '📦',
                ),
                _SummaryRow(
                  label: context.l10n.packSummaryGameType,
                  value: _gameTypeName(context, draft.gameType),
                  icon: '🎮',
                ),
                _SummaryRow(
                  label: context.l10n.packSummaryCards,
                  value: context.l10n.packSummaryCardsValue(
                    draft.cards.length,
                    draft.truthCount,
                    draft.dareCount,
                  ),
                  icon: '🃏',
                ),
                _SummaryRow(
                  label: context.l10n.packSummaryPrice,
                  value: context.l10n.packPriceMru(draft.priceMru),
                  icon: '💰',
                ),
                _SummaryRow(
                  label: context.l10n.packSummarySpicyContent,
                  value: draft.allowSpicy
                      ? context.l10n.packAllowedLabel
                      : context.l10n.no,
                  icon: '🌶',
                ),
              ],
            ),
          ).animate(delay: 80.ms).fadeIn(),

          const SizedBox(height: 16),

          // Eligibility — item 12/13's explicit requirement: show free-
          // submission availability, the next-free date if unavailable, and
          // the database-configured paid option up front, never hidden
          // behind a separate screen. Server-authoritative regardless —
          // this card is read-only UX, submitForReview() re-verifies
          // everything itself.
          _EligibilityCard(status: _status, loading: _loadingStatus)
              .animate(delay: 85.ms)
              .fadeIn(),

          const SizedBox(height: 16),

          // Blocking issues — explicit, localized reasons the pack can't yet be
          // submitted, so the disabled button is never a dead end.
          if (issues.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.errorRed.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.packIssuesHeader,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final issue in issues)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '•  ${_issueMessage(context, issue)}',
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                ],
              ),
            ).animate(delay: 90.ms).fadeIn(),

          if (issues.isNotEmpty) const SizedBox(height: 16),

          // Rules reminder
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.infoBlue.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.packImportantRulesTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.packImportantRulesBody,
                  style: const TextStyle(fontSize: 13, height: 1.6),
                ),
              ],
            ),
          ).animate(delay: 100.ms).fadeIn(),

          const SizedBox(height: 16),

          // Terms acceptance — explicit checkbox + a readable link to the full
          // terms. Merely opening the terms never counts as acceptance.
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () =>
                setState(() => draft.termsAccepted = !draft.termsAccepted),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: draft.termsAccepted,
                    onChanged: (v) =>
                        setState(() => draft.termsAccepted = v ?? false),
                  ),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(context.l10n.packTermsAgreePrefix),
                        GestureDetector(
                          onTap: () => _showPackTerms(context),
                          child: Text(
                            context.l10n.packTermsAgreeLink,
                            style: TextStyle(
                              color: AppColors.navyBlue,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: 110.ms).fadeIn(),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  child: Text(context.l10n.back),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: JButton(
                  label: (_status != null && !_status!.canSubmitFree)
                      ? context.l10n.packCreateExtraPackPriced(
                          _status!.extraPackPriceMru,
                        )
                      : context.l10n.packSubmitForReview,
                  onPressed: canPublish ? widget.onPublish : null,
                  isLoading: widget.isSaving,
                  icon: Icons.send_rounded,
                ),
              ),
            ],
          ).animate(delay: 120.ms).fadeIn(),
        ],
      ),
    );
  }
}

/// Localized, human-readable explanation for each blocking submission issue.
String _issueMessage(BuildContext context, PackDraftIssue issue) =>
    switch (issue) {
      PackDraftIssue.title => context.l10n.packIssueTitle,
      PackDraftIssue.cards => context.l10n.packIssueCards,
      PackDraftIssue.language => context.l10n.packIssueLanguage,
      PackDraftIssue.price => context.l10n.packIssuePrice(
        AppConstants.minPaidPackPriceMru,
      ),
      PackDraftIssue.truthDareBalance => context.l10n.packIssueBalance,
      PackDraftIssue.punishments => context.l10n.packIssuePunishments,
      PackDraftIssue.terms => context.l10n.packIssueTerms,
      PackDraftIssue.playerRange => context.l10n.packIssuePlayerRange,
    };

/// Read-only Pack Creation Terms sheet — same modal-sheet style as the rest of
/// the app; localized. Opening it never implies acceptance (that's the
/// checkbox's job).
void _showPackTerms(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ctx.l10n.packTermsTitle,
              style: ctx.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ctx.l10n.packTermsBody,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Item 12/13 — free-submission-availability, next-free-date, and the
/// database-configured paid-extra-pack option, shown clearly before the
/// submit CTA rather than only surfacing at the moment of failure. Purely
/// presentational (the server independently re-verifies everything in
/// submitForReview()); [status] is null while still loading or if the
/// preflight call failed, in which case a neutral loading/unknown state
/// is shown instead of guessing.
class _EligibilityCard extends StatelessWidget {
  const _EligibilityCard({required this.status, required this.loading});
  final PackCreationStatus? status;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;

    if (loading) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.packEligibilityChecking,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final s = status;
    final isFree = s?.canSubmitFree ?? true;
    final color = isFree ? AppColors.successGreen : AppColors.warningAmber;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFree ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFree
                      ? l10n.packFreeSubmissionAvailable
                      : l10n.packFreeSubmissionUnavailable,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (!isFree && s?.nextFreeAt != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.packNextFreeSubmissionAt(_formatDate(s!.nextFreeAt!)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (!isFree) ...[
            const SizedBox(height: 4),
            Text(
              l10n.packPaidExtraPackHint(s?.extraPackPriceMru ?? 0),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
