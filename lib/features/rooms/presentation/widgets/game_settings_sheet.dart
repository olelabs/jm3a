import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/platform_config_provider.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/services/image_cache_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/settings_row_widgets.dart';
import '../../../games/engine/base_game_engine.dart' show GameType;
import '../../../packs/data/pack_repository.dart';
import '../../../packs/domain/pack_situation_tags.dart';
import '../../../packs/presentation/pack_provider.dart';
import '../../../packs/presentation/widgets/pack_situation_tag_picker.dart';
import '../room_provider.dart';

/// The pack's own title in [lang] if available, else in the pack's
/// declared language, else in whatever language it actually has —
/// [PackEntity.titleFor] never returns a raw id. Only truly empty title
/// data (a corrupt/incomplete pack row) falls through to the generic
/// localized "Pack" placeholder — never the pack's UUID.
///
/// Item 5 (real-device report) — [lang] must be the ROOM's own selected
/// language (RoomEntity.language / this screen's own `_langFilter`
/// state), NOT the viewer's app UI language
/// (`Localizations.localeOf(context)`, the previous — wrong — source):
/// an admin whose own phone is set to English but who picked Arabic for
/// the room should see Arabic pack names here, since that's what every
/// OTHER player in the room will actually see the pack as.
String _displayTitle(BuildContext context, PackEntity pack, String lang) {
  final title = pack.titleFor(lang);
  return title.isNotEmpty ? title : context.l10n.defaultPackName;
}

/// Item 9 (real-device report) — Room Settings language chips used to
/// always show raw 2-letter codes ("EN"/"FR"/"AR") uppercased,
/// regardless of the viewer's own app language. Localizes en/ar/fr's
/// display name using the APP's current UI language ([l10n] — see
/// edit_profile_screen.dart/onboarding_screen.dart for the same
/// language-name keys used the same way) — deliberately NOT the room's
/// own selected language (RoomEntity.language/_langFilter, a completely
/// separate field this function never reads: which language a chip's
/// LABEL is written in, and which language that chip SELECTS, are two
/// independent things). Codes without a localized name (the
/// pack_languages table can list more than en/ar/fr) keep the existing
/// uppercase-code fallback.
String languageLabel(AppLocalizations l10n, String code) => switch (code) {
  'en' => l10n.languageEnglish,
  'ar' => l10n.languageArabic,
  'fr' => l10n.languageFrench,
  _ => code.toUpperCase(),
};

/// Item 6 (real-device report) — the actual category-match predicate a
/// pack must satisfy: `categoryId == null` means "All categories" (no
/// filter, matches everything, including packs with no category set at
/// all), otherwise the pack's own [PackEntity.categoryId] must match
/// exactly. A top-level pure function (not inlined in _filteredPacks)
/// so this exact predicate is independently unit-testable without a
/// live PackProvider/Supabase client — the same established pattern as
/// every other extracted decision function in this codebase.
bool packMatchesCategory(PackEntity pack, String? categoryId) =>
    categoryId == null || pack.categoryId == categoryId;

class GameSettingsSheet extends StatefulWidget {
  const GameSettingsSheet({super.key, this.scrollController});

  /// Shares scroll position with an enclosing DraggableScrollableSheet so
  /// dragging the sheet handle and scrolling the content are the same
  /// gesture instead of two competing ones.
  final ScrollController? scrollController;

  @override
  State<GameSettingsSheet> createState() => _GameSettingsSheetState();
}

class _GameSettingsSheetState extends State<GameSettingsSheet> {
  List<PackEntity> _packs = [];
  bool _loadingPacks = true;
  String _langFilter = 'en';
  Set<String> _playedPackIds = {}; // packs already used in this room

  // Item 6 (real-device report) — category filter. Null means "All
  // categories" (no filtering by category, the existing behavior).
  // Client-side against the already-loaded _packs, same as _langFilter/
  // _packTab above — GameSettingsSheet builds its pack list from
  // provider state already in memory (purchased + local + free browse
  // packs), not a fresh per-filter server fetch, so this stays
  // consistent with how every other filter in this sheet already works.
  // Because ToD/NHIE/Meme packs are all picked from this ONE sheet
  // (only _packTab changes which game's packs are visible), this single
  // filter automatically applies uniformly across all three games
  // rather than needing three separate implementations.
  String? _categoryFilter;

  // Optional admin "what are you looking for" filter (item 5). Empty by
  // default — existing pack browsing is completely unchanged until the
  // admin actually picks something (see rankPacksBySituation). ToD-only
  // (item 7) — never consulted for NHIE/Meme tabs.
  final Set<String> _selectedTags = {};

  // Item 7: DB-driven situation-tag vocabulary, loaded once like every
  // other admin-configurable list this sheet already fetches (languages).
  List<PackSituationTag> _situationTags = [];

  // Item 6 (real-device report) — DB-driven category vocabulary.
  // PackProvider already loads this once on login (_loadCategories, see
  // its own onUserLoggedIn), so this is a one-shot read of already-
  // available state in initState, same convention as _situationTags
  // above rather than a live context.watch<PackProvider>() — nothing
  // else in this sheet reactively watches PackProvider either.
  List<PackCategory> _categories = [];

  // Item 6: which game's packs the picker currently shows. Defaults to the
  // room's own active game so opening the sheet never changes what's
  // visible by default; the admin can switch tabs to browse another
  // game's packs without it affecting the room's current game type.
  late GameType _packTab;

  // packId → languages every active card actually has content for.
  // Populated alongside _packs in _loadPacks(); used so the filter below
  // can't be fooled by a pack whose metadata claims a language but whose
  // cards were never actually translated.
  Map<String, Set<String>> _cardLanguages = {};

  // Small display-only lookup, not a source of truth — the actual list of
  // *available* languages always comes from the pack_languages table via
  // _loadLanguages(). A code with no entry here just falls back to a
  // generic flag emoji, it's never excluded from the list.
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

  // Just the available codes — the display LABEL (item 9) is derived at
  // render time from the app's current UI language via languageLabel(),
  // not baked in here, so it can't go stale if the app language changes
  // while this sheet is open.
  List<String> _langs = [];

  @override
  void initState() {
    super.initState();
    // Reflect the room's actual language so the sheet shows the real
    // current state.
    _langFilter = context.read<RoomProvider>().room?.language ?? 'en';
    _packTab =
        context.read<RoomProvider>().room?.gameType ?? GameType.truthOrDare;
    _loadPacks();
    _loadLanguages();
    _loadSituationTags();
    _categories = context.read<PackProvider>().categories;
  }

  Future<void> _loadSituationTags() async {
    try {
      final tags = await PackRepository.instance.getSituationFilters();
      if (mounted) setState(() => _situationTags = tags);
    } catch (_) {
      // Best-effort — an empty picker just means no filters to offer this
      // session, never blocks the ordinary pack list below it.
    }
  }

  Future<void> _loadLanguages() async {
    try {
      final langs = await PackRepository.instance.getAvailableLanguages();
      if (!mounted) return;
      setState(() {
        _langs = [for (final l in langs) l.code];
      });
    } catch (_) {
      // Fall back to just the room's own current language — never block
      // the sheet on this, and never silently hardcode a fixed set.
      if (mounted) {
        setState(() => _langs = [_langFilter]);
      }
    }
  }

  Future<void> _loadPacks() async {
    try {
      final packProvider = context.read<PackProvider>();
      final owned = [
        ...packProvider.purchasedPacks,
        ...packProvider.localPacks,
        ...packProvider.browsePacks.where((p) => p.isFree),
      ];
      final seen = <String>{};
      final unique = owned.where((p) => seen.add(p.id)).toList();

      // Best-effort: if this lookup fails for any reason, fall back to
      // trusting pack metadata alone rather than blocking the picker.
      var coverage = <String, Set<String>>{};
      try {
        coverage = await PackRepository.instance.getCardLanguageCoverage(
          unique.map((p) => p.id).toList(),
        );
      } catch (_) {}

      // Load which packs have already been played in this room so we
      // can grey them out in the picker (can't reuse a pack per room).
      var playedIds = <String>{};
      try {
        final roomId = context.read<RoomProvider>().room?.id;
        if (roomId != null) {
          playedIds = await sl.roomRepository.getPlayedPackIds(roomId);
        }
      } catch (_) {}

      if (mounted)
        setState(() {
          _packs = unique;
          _cardLanguages = coverage;
          _playedPackIds = playedIds;
          _loadingPacks = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loadingPacks = false);
    }
  }

  List<PackEntity> get _filteredPacks {
    return _packs.where((p) {
      // Item 6: only the currently selected game-type tab's packs — this
      // is purely additive to the existing language/coverage filtering
      // below, never changes it.
      if (p.gameType != _packTab.toDbString()) return false;

      // Item 6 (real-device report) — category filter, purely additive
      // to every other predicate here (game tab + language/coverage).
      if (!packMatchesCategory(p, _categoryFilter)) return false;

      // Title/metadata must claim the language...
      final titleHasLang = p.titleJson.containsKey(_langFilter);
      if (!titleHasLang) return false;

      // ...and the actual cards must really have it too. If the coverage
      // lookup didn't return anything for this pack (e.g. it failed, or
      // the pack has zero cards), fall back to the metadata flags so a
      // pack isn't hidden just because of a lookup hiccup.
      final knownCoverage = _cardLanguages[p.id];
      if (knownCoverage != null) {
        return knownCoverage.contains(_langFilter);
      }
      if (p.availableLanguages.isNotEmpty) {
        return p.availableLanguages.contains(_langFilter);
      }
      return p.language == _langFilter ||
          p.language == 'multi' ||
          p.isMultilang;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Consumer<RoomProvider>(
        builder: (_, room, __) {
          final s = room.settings;
          return SingleChildScrollView(
            controller: widget.scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  l10n.gameSettings,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Game tabs — FIRST, before language (this section's
                // whole reason to exist is picking which game's packs to
                // browse below, so it leads) ────────────────────────────
                // narrows the pack picker below to only that game's packs.
                // Purely a display filter (see _filteredPacks); doesn't
                // touch packId, selection state, or the room's own game
                // type. Only meaningful (and only shown) for the owner,
                // same as the pack picker itself below.
                if (room.isOwner) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: GameType.values.map((gt) {
                        final label = switch (gt) {
                          GameType.truthOrDare => l10n.gameNameTruthOrDare,
                          GameType.neverHaveIEver =>
                            l10n.gameNameNeverHaveIEver,
                          GameType.memeGame => l10n.gameNameMeme,
                        };
                        final selected = _packTab == gt;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            avatar: Text(
                              gt.icon,
                              style: const TextStyle(fontSize: 18),
                            ),
                            label: Text(label),
                            labelStyle: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurface,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            selected: selected,
                            onSelected: (_) => setState(() => _packTab = gt),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Language filter ──────────────────────────────────────────
                Text(
                  l10n.profileLanguageLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _langs.map((code) {
                      final selected = _langFilter == code;
                      final label =
                          '${_flagEmoji[code] ?? '🏳️'} ${languageLabel(l10n, code)}';
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _langFilter = code);
                            room.setLanguage(code);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Category filter (item 6, real-device report) ─────────────
                // Purely additive, same client-side-against-_packs pattern as
                // the language filter above; shown only when there's
                // actually more than "everything" to filter by, and only
                // for the owner, matching the game tabs/pack picker above.
                if (room.isOwner && _categories.isNotEmpty) ...[
                  Text(
                    l10n.roomSettingsCategoryFilterLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(l10n.gameNameAll),
                            selected: _categoryFilter == null,
                            onSelected: (_) =>
                                setState(() => _categoryFilter = null),
                          ),
                        ),
                        for (final category in _categories)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                '${category.icon} ${category.nameFor(_langFilter)}',
                              ),
                              selected: _categoryFilter == category.id,
                              onSelected: (_) =>
                                  setState(() => _categoryFilter = category.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Pack picker ───────────────────────────────────────────────
                if (room.isOwner) ...[
                  Text(
                    l10n.gameSettingsSelectPack,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_loadingPacks)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_packs
                      .where((p) => p.gameType == _packTab.toDbString())
                      .isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.gameSettingsNoPacksDevMsg,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Builder(
                      builder: (_) {
                        // A pack already played in this room is removed
                        // from selection entirely, immediately at game
                        // start — no exemption for the room's current
                        // session pack. Never wait for another pack to be
                        // selected before this one disappears.
                        final visiblePacks = _filteredPacks
                            .where((p) => !_playedPackIds.contains(p.id))
                            .toList();
                        // Item 7: the situation-tag filter/ranking applies
                        // ONLY to ToD — NHIE/Meme always see the plain,
                        // unranked pack list, same as before this filter
                        // ever existed.
                        final isTod = _packTab == GameType.truthOrDare;
                        // Item 7: deterministic ranking — a no-op (same
                        // list, same order) whenever _selectedTags is
                        // empty, per item 5's "existing behavior
                        // unchanged" requirement.
                        final ranked = isTod
                            ? rankPacksBySituation(visiblePacks, _selectedTags)
                            : visiblePacks;
                        final matched = (!isTod || _selectedTags.isEmpty)
                            ? const <PackEntity>[]
                            : ranked
                                  .where(
                                    (p) =>
                                        p.situationMatchCount(_selectedTags) >
                                        0,
                                  )
                                  // Capped — "not so visually dominant it
                                  // becomes confusing or unusable".
                                  .take(3)
                                  .toList();
                        final others = matched.isEmpty
                            ? ranked
                            : ranked
                                  .where((p) => !matched.contains(p))
                                  .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isTod) ...[
                              PackSituationTagPicker(
                                title: l10n.packSituationFilterTitle,
                                subtitle: l10n.packSituationFilterSubtitle,
                                tags: _situationTags,
                                selected: _selectedTags,
                                onToggle: (slug) => setState(() {
                                  if (!_selectedTags.remove(slug)) {
                                    _selectedTags.add(slug);
                                  }
                                }),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (matched.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 16,
                                    color: AppColors.ownerBadge,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.packBestMatchTitle,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ownerBadge,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...matched.map(
                                (pack) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _BestMatchPackCard(
                                    pack: pack,
                                    matchedTags: pack.tags
                                        .where(_selectedTags.contains)
                                        .toList(),
                                    situationTags: _situationTags,
                                    selected: room.room?.packId == pack.id,
                                    onTap: () => room.setPackId(pack.id),
                                    language: _langFilter,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.packOtherPacksTitle,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            SizedBox(
                              // Item 8 (real-device report) — was 110,
                              // exactly tall enough for a SINGLE-line
                              // pack title. _PackPickerCard's title is
                              // maxLines: 2, and once a long pack name
                              // actually wraps to its second line, the
                              // card's intrinsic content height (icon
                              // row + both title lines + card-count row
                              // + padding) exceeds 110, producing a
                              // bottom RenderFlex overflow. 136 gives
                              // enough room for the full 2-line case
                              // without touching any font size, per
                              // this task's own "do not shrink fonts to
                              // fit" instruction.
                              height: 136,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: others.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (ctx, i) => _PackPickerCard(
                                  pack: others[i],
                                  selected: room.room?.packId == others[i].id,
                                  onTap: () => room.setPackId(others[i].id),
                                  language: _langFilter,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                ],

                // ── Game settings ─────────────────────────────────────────────
                // Item 11 — explicit Timer ON/OFF, applying identically to
                // ToD/NHIE/Meme (the ONE existing GameConfig.timerEnabled
                // convention — turnTimerSeconds > 0 — already used by
                // ToD's timer and now NHIE's/Meme's too; no per-game
                // duplicate setting). The slider below previously had no
                // way to reach 0 at all (min: 15), so there was actually
                // no way for the admin to turn the timer off before this.
                SettingsSwitchRow(
                  label: l10n.gameSettingsTurnTimer,
                  icon: Icons.timer_outlined,
                  value: s.turnTimerSeconds > 0,
                  onChanged: (v) =>
                      room.updateSetting('turn_timer_secs', v ? 30 : 0),
                ),
                if (s.turnTimerSeconds > 0)
                  SettingsSliderRow(
                    label: l10n.gameSettingsSeconds(s.turnTimerSeconds),
                    value: s.turnTimerSeconds.toDouble(),
                    display: l10n.gameSettingsSeconds(s.turnTimerSeconds),
                    min: 15,
                    max: 120,
                    divisions: 21,
                    onChanged: (v) =>
                        room.updateSetting('turn_timer_secs', v.round()),
                  ),
                Builder(
                  builder: (_) {
                    // Items 2/3/4/6/7 — NHIE and Meme's engines have no
                    // repeat mode at all (every card/prompt is always
                    // unique within a game — see never_have_i_ever_engine
                    // .dart's/meme_game_engine.dart's used-id tracking),
                    // so for these two tabs Max Rounds can never exceed
                    // the selected pack's own card count. ToD's own
                    // 'unique'/'shuffle' choice isn't made until the
                    // pre-game sheet (see tod_pre_game_config_sheet.dart),
                    // so this general settings sheet leaves its range
                    // uncapped for the ToD tab — the authoritative check
                    // that actually blocks an impossible value either way
                    // is server-side (create_game_session), not this UI.
                    final selectedPack = _packs
                        .where((p) => p.id == room.room?.packId)
                        .firstOrNull;
                    final capped =
                        _packTab != GameType.truthOrDare &&
                        selectedPack != null;
                    final cap = capped ? selectedPack.cardCount : 30;
                    final sliderMax = capped
                        ? (cap < 3 ? 3.0 : cap.toDouble())
                        : 30.0;
                    // Item 4 — never silently change the value: if the
                    // currently-persisted Max Rounds is above what this
                    // pack can actually support, auto-reduce it (with the
                    // caption below explaining why) rather than leaving an
                    // impossible configuration selected.
                    if (capped && cap >= 1 && s.maxRounds > cap) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) room.updateSetting('max_rounds', cap);
                      });
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingsSliderRow(
                          label: l10n.gameSettingsMaxRounds,
                          value: s.maxRounds.toDouble().clamp(3, sliderMax),
                          display: '${s.maxRounds}',
                          min: 3,
                          max: sliderMax,
                          divisions: (sliderMax - 3).round().clamp(1, 27),
                          onChanged: (v) =>
                              room.updateSetting('max_rounds', v.round()),
                        ),
                        if (capped)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              l10n.gameSettingsMaxRoundsCapHint(cap),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 4),
                SettingsSwitchRow(
                  label: l10n.chatTitle,
                  icon: Icons.chat_bubble_outline_rounded,
                  value: s.chatEnabled,
                  onChanged: (v) => room.updateSetting('chat_enabled', v),
                ),
                SettingsSwitchRow(
                  label: l10n.gameSettingsAllowSpectators,
                  icon: Icons.visibility_outlined,
                  value: s.allowSpectators,
                  onChanged: (v) => room.updateSetting('allow_spectators', v),
                ),
                // Approval gate only makes sense when spectators are enabled
                if (s.allowSpectators)
                  SettingsSwitchRow(
                    label: l10n.gameSettingsRequireApprovalToSpectate,
                    icon: Icons.how_to_reg_outlined,
                    value: s.spectatorApprovalRequired,
                    onChanged: (v) =>
                        room.updateSetting('spectator_approval_required', v),
                  ),
                // Admin feature flag (item 2) — hidden entirely when spicy
                // content is platform-disabled. This is presentation only;
                // the game_sessions BEFORE INSERT/UPDATE trigger is what
                // actually clamps allow_spicy server-side regardless of
                // what this toggle (or a modified client) sends.
                if (context.watch<PlatformConfigProvider>().spicyContentEnabled)
                  SettingsSwitchRow(
                    label: l10n.gameSettingsSpicy,
                    icon: Icons.local_fire_department_outlined,
                    value: s.allowSpicy,
                    onChanged: (v) => room.updateSetting('allow_spicy', v),
                  ),
                SettingsSwitchRow(
                  label: l10n.gameSettingsRequireApproval,
                  icon: Icons.lock_outline_rounded,
                  value: s.requiresApproval,
                  onChanged: (v) => room.updateSetting('requires_approval', v),
                ),
                SettingsSwitchRow(
                  label: l10n.gameSettingsHonestyVote,
                  icon: Icons.handshake_outlined,
                  value: s.honestyVoteEnabled,
                  onChanged: (v) =>
                      room.updateSetting('honesty_vote_enabled', v),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Item 8 — premium hero card for a top-ranked pack. Larger than the
/// ordinary picker card, real cover artwork, a gold "best match" accent,
/// and an explicit checklist of which selected situations it matches.
class _BestMatchPackCard extends StatelessWidget {
  const _BestMatchPackCard({
    required this.pack,
    required this.matchedTags,
    required this.situationTags,
    required this.selected,
    required this.onTap,
    required this.language,
  });

  final PackEntity pack;
  final List<String> matchedTags;
  final List<PackSituationTag> situationTags;
  final bool selected;
  final VoidCallback onTap;

  /// The room's own selected language (item 5) — see _displayTitle's
  /// own doc comment for why this must not be the viewer's app locale.
  final String language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : AppColors.ownerBadge.withValues(alpha: 0.5),
            width: selected ? 2.2 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.ownerBadge.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            children: [
              SizedBox(
                height: 150,
                width: double.infinity,
                child: ImageCacheService.instance.packCover(
                  url: pack.coverImageUrl,
                  width: double.infinity,
                  height: 150,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.82),
                      ],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ownerBadge,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.packMatchedLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                    size: 26,
                    shadows: const [
                      Shadow(color: Colors.black45, blurRadius: 4),
                    ],
                  ),
                ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _displayTitle(context, pack, language),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: matchedTags
                          .map(
                            (slug) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    packSituationTagLabel(
                                      context,
                                      slug,
                                      situationTags,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The ordinary pack picker card — unchanged visual, extracted so both the
/// no-filter path and the "Other packs" section under a Best Match list
/// use the exact same existing card (item 8: "Use the existing pack cards
/// for the remaining packs").
class _PackPickerCard extends StatelessWidget {
  const _PackPickerCard({
    required this.pack,
    required this.selected,
    required this.onTap,
    required this.language,
  });

  final PackEntity pack;
  final bool selected;
  final VoidCallback onTap;

  /// The room's own selected language (item 5) — see _displayTitle's
  /// own doc comment for why this must not be the viewer's app locale.
  final String language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(pack.coverEmoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 4),
                Tooltip(
                  message: switch (pack.genderRestriction) {
                    'male' => l10n.packGenderMaleOnly,
                    'female' => l10n.packGenderFemaleOnly,
                    _ => l10n.packAudienceEveryone,
                  },
                  child: Text(switch (pack.genderRestriction) {
                    'male' => '👨',
                    'female' => '👩',
                    _ => '👥',
                  }, style: const TextStyle(fontSize: 13)),
                ),
                const Spacer(),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _displayTitle(context, pack, language),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.packCardCount(pack.cardCount),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _PackX on PackEntity {
  String get coverEmoji {
    if (titleJson['en']?.toString().toLowerCase().contains('arabic') == true)
      return '🌙';
    if (titleJson['en']?.toString().toLowerCase().contains('party') == true)
      return '🎉';
    return '🎮';
  }
}
