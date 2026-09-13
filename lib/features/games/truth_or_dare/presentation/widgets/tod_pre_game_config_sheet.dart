import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/extensions/context_ext.dart';
import '../../../../../core/services/image_cache_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/settings_row_widgets.dart';
import '../../../../packs/data/pack_repository.dart';

/// Result of the pre-game Truth or Dare setup sheet — becomes part of the
/// game's immutable GameConfig the moment "Confirm & Start" is pressed.
/// Never editable again once the game starts (see GameConfig's own
/// force-dare/card-repetition doc comments) — reconnecting players and
/// spectators receive this exact same config via the persisted game
/// session snapshot, not a fresh read of room settings.
class TodPreGameConfig {
  const TodPreGameConfig({
    required this.enablePunishments,
    required this.punishmentSource,
    required this.allowSkip,
    required this.forceDareMode,
    required this.maxTruths,
    required this.cardRepetitionMode,
  });

  final bool enablePunishments;
  final String punishmentSource; // 'pack' | 'players'
  final bool allowSkip;
  final String forceDareMode; // 'unlimited' | 'per_player' | 'per_turn'
  final int maxTruths;
  final String cardRepetitionMode; // 'shuffle' | 'unique'
}

/// Shown between "Start Game" and actually starting, for Truth or Dare
/// only (see lobby_screen.dart's onStartGame) — every other game continues
/// starting exactly as before, unaffected by this sheet's existence.
/// Returns null if the host backs out without confirming.
///
/// Proof visibility/viewing-timer are NOT configured here — the submitting
/// player now chooses them immediately before pressing Done on a Dare (see
/// TodCardScreen._showCompleteSheet's _ProofVisibilitySelector /
/// _ProofTimerSelector), never as a game-wide default.
Future<TodPreGameConfig?> showTodPreGameConfigSheet(
  BuildContext context, {
  required PackEntity? pack,
  // Item 3 (real-device report) root-cause fix: this sheet used to
  // always initialize _allowSkip to a hardcoded `true`, regardless of
  // what the room's admin had actually already configured — see this
  // parameter's own doc comment on _TodPreGameConfigSheet.
  bool initialAllowSkip = true,
}) {
  return showModalBottomSheet<TodPreGameConfig>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _TodPreGameConfigSheet(pack: pack, initialAllowSkip: initialAllowSkip),
  );
}

class _TodPreGameConfigSheet extends StatefulWidget {
  const _TodPreGameConfigSheet({this.pack, this.initialAllowSkip = true});
  final PackEntity? pack;

  /// The room's actual currently-persisted allow-skip setting
  /// (RoomSettingsEntity.allowSkip), so this sheet reflects reality
  /// instead of always starting from a hardcoded `true` — see item 3's
  /// own root-cause note at the Allow Skip row below.
  final bool initialAllowSkip;

  @override
  State<_TodPreGameConfigSheet> createState() => _TodPreGameConfigSheetState();
}

class _TodPreGameConfigSheetState extends State<_TodPreGameConfigSheet> {
  bool _enablePunishments = false;
  String _punishmentSource = 'players';
  late bool _allowSkip = widget.initialAllowSkip;
  String _forceDareMode = 'unlimited';
  int _maxTruths = 2;
  String _cardRepetitionMode = 'shuffle';

  // Only offer the pack-sourced punishment mode when the selected pack
  // actually has a valid (>=10, enforced at pack-creation time) authored
  // list — otherwise silently behave as 'players' (see requirement: "If
  // the pack has no punishments: Automatically use Players decide").
  bool get _hasPackPunishments =>
      (widget.pack?.suggestedPunishments.length ?? 0) >= 10;

  @override
  void initState() {
    super.initState();
    if (_hasPackPunishments) _punishmentSource = 'pack';
  }

  void _confirm() {
    Navigator.of(context).pop(
      TodPreGameConfig(
        enablePunishments: _enablePunishments,
        punishmentSource: _hasPackPunishments ? _punishmentSource : 'players',
        allowSkip: _allowSkip,
        forceDareMode: _forceDareMode,
        maxTruths: _maxTruths,
        cardRepetitionMode: _cardRepetitionMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Header ────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.brandPurpleMid,
                          AppColors.brandBlueMid,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandPurpleMid.withValues(
                            alpha: 0.35,
                          ),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.todConfigTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.todConfigSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close (X) — backs out without confirming (returns null,
                  // same as a drag-dismiss), so the game does not start.
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    style: IconButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 250.ms),

              const SizedBox(height: 18),

              // ── Pack preview — the pack itself was already chosen
              // earlier (game_settings_sheet.dart); this is a confirmation
              // hero, not a picker, so nothing here changes settings
              // behavior.
              if (widget.pack != null)
                _PackPreviewCard(pack: widget.pack!)
                    .animate(delay: 40.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),

              const SizedBox(height: 16),

              // ── Punishments ──────────────────────────────────────────
              _SectionCard(
                index: 0,
                accent: AppColors.spicyColor,
                icon: Icons.gavel_rounded,
                title: l10n.gameSettingsPunishmentMode,
                trailing: Switch(
                  value: _enablePunishments,
                  onChanged: (v) => setState(() => _enablePunishments = v),
                ),
                child: _enablePunishments
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_hasPackPunishments) ...[
                              Text(
                                l10n.gameSettingsPunishmentHintPackAvailable,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SegmentedButton<String>(
                                segments: [
                                  ButtonSegment(
                                    value: 'pack',
                                    label: Text(
                                      l10n.gameSettingsPackPunishments,
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: 'players',
                                    label: Text(l10n.gameSettingsPlayersSubmit),
                                  ),
                                ],
                                selected: {_punishmentSource},
                                onSelectionChanged: (v) =>
                                    setState(() => _punishmentSource = v.first),
                                style: const ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ] else
                              Text(
                                l10n.gameSettingsPunishmentHintDefault,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      )
                    : null,
              ),

              const SizedBox(height: 12),

              // ── Allow Skip — item 3 (real-device report) root-cause fix:
              // this used to be nested INSIDE the Punishments section's
              // `_enablePunishments ? ... : null` conditional child, so it
              // only ever rendered once the admin also turned Punishments
              // on (default off) — in the common case the admin could
              // never see or disable this toggle at all, and _allowSkip
              // stayed hardcoded at its initial `true` every time. Now a
              // standalone, always-visible row, independent of
              // Punishments, and initialized from the room's actual
              // current setting (see this sheet's own constructor/
              // initState) instead of a hardcoded default.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SettingsSwitchRow(
                  label: l10n.gameSettingsAllowSkip,
                  icon: Icons.skip_next_rounded,
                  value: _allowSkip,
                  onChanged: (v) => setState(() => _allowSkip = v),
                ),
              ),

              // ── Force Dare rules ─────────────────────────────────────
              _SectionCard(
                index: 1,
                accent: AppColors.dareColor,
                icon: Icons.local_fire_department_rounded,
                title: l10n.todConfigForceDareTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'unlimited',
                          label: Text(l10n.todConfigForceDareUnlimited),
                        ),
                        ButtonSegment(
                          value: 'per_player',
                          label: Text(l10n.todConfigForceDarePerPlayer),
                        ),
                        ButtonSegment(
                          value: 'per_turn',
                          label: Text(l10n.todConfigForceDarePerTurn),
                        ),
                      ],
                      selected: {_forceDareMode},
                      onSelectionChanged: (v) =>
                          setState(() => _forceDareMode = v.first),
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    // Progressive reveal: the truth-limit slider is
                    // meaningless in Unlimited mode.
                    if (_forceDareMode != 'unlimited')
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: SettingsSliderRow(
                          label: l10n.todConfigMaxTruths,
                          value: _maxTruths.toDouble(),
                          display: '$_maxTruths',
                          min: 1,
                          max: 10,
                          divisions: 9,
                          onChanged: (v) =>
                              setState(() => _maxTruths = v.round()),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Card repetition ──────────────────────────────────────
              _SectionCard(
                index: 2,
                accent: AppColors.brandPurpleMid,
                icon: Icons.style_rounded,
                title: l10n.todConfigCardRepetitionTitle,
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'shuffle',
                      label: Text(l10n.todConfigCardRepetitionShuffle),
                    ),
                    ButtonSegment(
                      value: 'unique',
                      label: Text(l10n.todConfigCardRepetitionUnique),
                    ),
                  ],
                  selected: {_cardRepetitionMode},
                  onSelectionChanged: (v) =>
                      setState(() => _cardRepetitionMode = v.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              // Items 4/7 — informational only (the authoritative check is
              // server-side, in create_game_session — see
              // migration_2026_round_capacity_validation.sql): with
              // Unique Cards on, this pack can't sustain more rounds than
              // it has cards for (every player draws one card per round,
              // so a smaller room actually stretches further than a
              // large one; this shows the pack's raw card count as the
              // simplest honest number without guessing at final active
              // player count here).
              if (_cardRepetitionMode == 'unique' && widget.pack != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    l10n.todConfigUniqueCardsCapHint(widget.pack!.cardCount),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),
              // Premium gradient CTA — still calls _confirm, which pops the
              // exact same TodPreGameConfig; presentation only.
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandPurpleMid.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _confirm,
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.brandPurpleMid,
                            AppColors.brandBlueMid,
                          ],
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.todConfigConfirmStart,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate(delay: 360.ms).fadeIn().slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirmation hero for the pack already selected before this sheet opened
/// — not a picker. Cover image, gradient wash, title, and a couple of quick
/// facts (card count, min players, spicy availability) so the admin sees
/// exactly what they're about to play at a glance.
class _PackPreviewCard extends StatelessWidget {
  const _PackPreviewCard({required this.pack});
  final PackEntity pack;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    // titleFor already falls back through: viewer language -> the pack's
    // own declared language -> 'en' -> any non-empty value present (see
    // pickLocalized in pack_entity.dart) — only a genuinely corrupt pack
    // row (no title in ANY language) reaches this final guard, and even
    // then this must never render blank.
    final rawTitle = pack.titleFor(lang);
    final title = rawTitle.isNotEmpty ? rawTitle : context.l10n.defaultPackName;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 108,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandPurpleMid.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageCacheService.instance.packCover(
              url: pack.coverImageUrl,
              width: double.infinity,
              height: 108,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _PackFactChip(
                        icon: Icons.style_outlined,
                        label: '${pack.cardCount}',
                      ),
                      const SizedBox(width: 6),
                      _PackFactChip(
                        icon: Icons.groups_outlined,
                        label: '${pack.minPlayers}+',
                      ),
                      if (pack.hasSpicy) ...[
                        const SizedBox(width: 6),
                        _PackFactChip(
                          icon: Icons.local_fire_department_rounded,
                          label: '🌶',
                          color: AppColors.spicyColor,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackFactChip extends StatelessWidget {
  const _PackFactChip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// One settings group as a large, tappable-feeling card instead of a plain
/// Text label + Divider — icon badge in the section's own accent color,
/// title, optional trailing control (e.g. the Punishments on/off switch),
/// and the section's existing controls unchanged below. [child] is the
/// progressive-reveal content; null/empty sections still render just the
/// header row.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.index,
    required this.accent,
    required this.icon,
    required this.title,
    this.trailing,
    this.child,
  });

  final int index;
  final Color accent;
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              if (child != null) child!,
            ],
          ),
        )
        .animate(delay: (90 + index * 70).ms)
        .fadeIn(duration: 260.ms)
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOut);
  }
}
