import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/platform_config_provider.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/services/image_cache_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/settings_row_widgets.dart';
import '../../../games/engine/base_game_engine.dart' show GameType;
import '../../../packs/data/pack_repository.dart';
import '../../../packs/domain/pack_situation_tags.dart';
import '../../../packs/presentation/pack_provider.dart';
import '../../../packs/presentation/widgets/pack_situation_tag_picker.dart';
import '../room_provider.dart';

/// The pack's own title in the viewer's language if available, else in the
/// pack's declared language, else in whatever language it actually has —
/// [PackEntity.titleFor] never returns a raw id. Only truly empty title
/// data (a corrupt/incomplete pack row) falls through to the generic
/// localized "Pack" placeholder — never the pack's UUID.
String _displayTitle(BuildContext context, PackEntity pack) {
  final title = pack.titleFor(Localizations.localeOf(context).languageCode);
  return title.isNotEmpty ? title : context.l10n.defaultPackName;
}

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

  // Optional admin "what are you looking for" filter (item 5). Empty by
  // default — existing pack browsing is completely unchanged until the
  // admin actually picks something (see rankPacksBySituation). ToD-only
  // (item 7) — never consulted for NHIE/Meme tabs.
  final Set<String> _selectedTags = {};

  // Item 7: DB-driven situation-tag vocabulary, loaded once like every
  // other admin-configurable list this sheet already fetches (languages).
  List<PackSituationTag> _situationTags = [];

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

  List<(String, String)> _langs = [];

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
        _langs = [
          for (final l in langs)
            (l.code, '${_flagEmoji[l.code] ?? '🏳️'} ${l.code.toUpperCase()}'),
        ];
      });
    } catch (_) {
      // Fall back to just the room's own current language — never block
      // the sheet on this, and never silently hardcode a fixed set.
      if (mounted) {
        setState(() => _langs = [(_langFilter, _langFilter.toUpperCase())]);
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
                    children: _langs.map((lang) {
                      final selected = _langFilter == lang.$1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(lang.$2),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _langFilter = lang.$1);
                            room.setLanguage(lang.$1);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

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
                              height: 110,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: others.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (ctx, i) => _PackPickerCard(
                                  pack: others[i],
                                  selected: room.room?.packId == others[i].id,
                                  onTap: () => room.setPackId(others[i].id),
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
  });

  final PackEntity pack;
  final List<String> matchedTags;
  final List<PackSituationTag> situationTags;
  final bool selected;
  final VoidCallback onTap;

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
                      _displayTitle(context, pack),
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
  });

  final PackEntity pack;
  final bool selected;
  final VoidCallback onTap;

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
              _displayTitle(context, pack),
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
