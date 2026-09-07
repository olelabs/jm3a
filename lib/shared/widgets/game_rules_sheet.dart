import 'package:flutter/material.dart';

import '../../core/extensions/context_ext.dart';
import '../../features/games/engine/base_game_engine.dart';
import '../../features/rooms/domain/room_entity.dart';

/// Opens the rules sheet for [gameType], showing static how-to-play copy
/// plus a dynamic section reflecting the room's actual current settings —
/// so players always see the rules that actually apply, not a generic
/// description that might not match what the owner configured.
Future<void> showGameRulesSheet(
  BuildContext context, {
  required GameType gameType,
  GameConfig? config,
  RoomSettingsEntity? roomSettings,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => GameRulesSheet(
        gameType: gameType,
        config: config,
        roomSettings: roomSettings,
        scrollController: scrollController,
      ),
    ),
  );
}

/// A small IconButton for dropping into any game screen's AppBar.
class RulesButton extends StatelessWidget {
  const RulesButton({
    super.key,
    required this.gameType,
    this.config,
    this.roomSettings,
  });

  final GameType gameType;
  final GameConfig? config;
  final RoomSettingsEntity? roomSettings;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu_book_outlined),
      tooltip: context.l10n.sharedRules,
      onPressed: () => showGameRulesSheet(
        context,
        gameType: gameType,
        config: config,
        roomSettings: roomSettings,
      ),
    );
  }
}

class GameRulesSheet extends StatelessWidget {
  const GameRulesSheet({
    super.key,
    required this.gameType,
    this.config,
    this.roomSettings,
    this.scrollController,
  });

  final GameType gameType;
  final GameConfig? config;
  final RoomSettingsEntity? roomSettings;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            context.l10n.sharedGameRulesTitle(_gameTypeName(context, gameType)),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ..._staticSections(context, gameType).map(
            (s) => _RuleSection(title: s.$1, body: s.$2),
          ),
          const Divider(height: 32),
          Text(
            context.l10n.sharedRoomSettingsTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ..._dynamicRules(context, gameType, config, roomSettings).map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    r.$1,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(r.$2, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<(String, String)> _staticSections(
    BuildContext context,
    GameType type,
  ) {
    final l10n = context.l10n;
    return switch (type) {
      GameType.truthOrDare => [
        (l10n.sharedRuleObjective, l10n.sharedTodRuleObjective),
        (l10n.sharedRuleTurnFlow, l10n.sharedTodRuleTurnFlow),
        (l10n.sharedRuleScoring, l10n.sharedTodRuleScoring),
      ],
      GameType.neverHaveIEver => [
        (l10n.sharedRuleObjective, l10n.sharedNhieRuleObjective),
        (l10n.sharedRuleTurnFlow, l10n.sharedNhieRuleTurnFlow),
        (l10n.sharedRuleScoring, l10n.sharedNhieRuleScoring),
      ],
      GameType.memeGame => [
        (l10n.sharedRuleObjective, l10n.sharedMemeRuleObjective),
        (l10n.sharedRuleTurnFlow, l10n.sharedMemeRuleTurnFlow),
        (l10n.sharedRuleScoring, l10n.sharedMemeRuleScoring),
      ],
    };
  }

  static List<(IconData, String)> _dynamicRules(
    BuildContext context,
    GameType type,
    GameConfig? config,
    RoomSettingsEntity? settings,
  ) {
    final l10n = context.l10n;
    final rules = <(IconData, String)>[];
    final timerSecs = config?.turnTimerSeconds ?? settings?.turnTimerSeconds;
    if (timerSecs != null && timerSecs > 0) {
      rules.add((Icons.timer_outlined, l10n.sharedRuleTurnTimer(timerSecs)));
    } else {
      rules.add((Icons.timer_off_outlined, l10n.sharedRuleNoTurnTimer));
    }

    if (type == GameType.truthOrDare) {
      final allowSkip = config?.allowSkip ?? settings?.allowSkip ?? true;
      final enablePunishments =
          config?.enablePunishments ?? settings?.enablePunishments ?? false;
      if (allowSkip && enablePunishments) {
        rules.add((Icons.gavel_rounded, l10n.sharedRulePunishmentOn));
      } else if (!enablePunishments) {
        rules.add((Icons.block_rounded, l10n.sharedRulePunishmentOff));
      }

      // Proof visibility/replay are no longer a fixed, game-wide rule —
      // the submitting player now chooses them per-Dare immediately before
      // pressing Done (see TodCardScreen._showCompleteSheet), so there is
      // no single policy left to display here.
    }

    if (settings != null) {
      if (settings.allowSpectators) {
        rules.add((
          Icons.remove_red_eye_outlined,
          settings.spectatorApprovalRequired
              ? l10n.sharedRuleSpectatorsApprovalRequired
              : l10n.sharedRuleSpectatorsFreelyAllowed,
        ));
      } else {
        rules.add((
          Icons.visibility_off_outlined,
          l10n.sharedRuleSpectatorsNotAllowed,
        ));
      }
      if (settings.allowSpicy) {
        rules.add((
          Icons.local_fire_department_outlined,
          l10n.sharedRuleSpicyEnabled,
        ));
      }
    }

    return rules;
  }
}

String _gameTypeName(BuildContext context, GameType type) => switch (type) {
  GameType.truthOrDare => context.l10n.gameNameTruthOrDare,
  GameType.neverHaveIEver => context.l10n.gameNameNeverHaveIEver,
  GameType.memeGame => context.l10n.gameNameMeme,
};

class _RuleSection extends StatelessWidget {
  const _RuleSection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
