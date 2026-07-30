import 'package:flutter/material.dart';

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
      tooltip: 'Rules',
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
            '${gameType.displayName} — Rules',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ..._staticSections(gameType).map(
            (s) => _RuleSection(title: s.$1, body: s.$2),
          ),
          const Divider(height: 32),
          Text(
            'This room\'s settings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ..._dynamicRules(gameType, config, roomSettings).map(
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

  static List<(String, String)> _staticSections(GameType type) =>
      switch (type) {
        GameType.truthOrDare => const [
          (
            'Objective',
            'Take turns choosing Truth or Dare. Answer honestly or complete '
                'the dare — there\'s no "safe" option once you\'ve picked.',
          ),
          (
            'Turn flow',
            'The current player picks Truth or Dare, gets a card, and '
                'either answers/performs it or (if allowed) skips. Then play '
                'passes to the next player in order.',
          ),
          (
            'Scoring',
            'Completed truths and dares add to your score. Skips are '
                'tracked too — they may trigger a punishment (see below).',
          ),
        ],
        GameType.neverHaveIEver => const [
          (
            'Objective',
            'Each round shows a "Never have I ever…" statement. Everyone '
                'answers honestly whether they have or haven\'t.',
          ),
          (
            'Turn flow',
            'A new statement appears each round; every player votes, then '
                'the round advances once everyone has answered.',
          ),
          (
            'Scoring',
            'Your history of honest answers builds your profile across the '
                'game — there\'s no winner/loser, just revealing.',
          ),
        ],
        GameType.memeGame => const [
          (
            'Objective',
            'Submit the funniest caption or sticker for the round\'s prompt, '
                'then vote for your favorite from everyone else\'s.',
          ),
          (
            'Turn flow',
            'Submission phase → voting phase → results, every round, until '
                'the pack\'s prompts run out or the round limit is hit.',
          ),
          (
            'Scoring',
            'Whoever gets the most votes on a round wins that round\'s '
                'point. Most points at the end wins the game.',
          ),
        ],
      };

  static List<(IconData, String)> _dynamicRules(
    GameType type,
    GameConfig? config,
    RoomSettingsEntity? settings,
  ) {
    final rules = <(IconData, String)>[];
    final timerSecs = config?.turnTimerSeconds ?? settings?.turnTimerSeconds;
    if (timerSecs != null && timerSecs > 0) {
      rules.add((Icons.timer_outlined, 'Turn timer: ${timerSecs}s'));
    } else {
      rules.add((Icons.timer_off_outlined, 'No turn timer'));
    }

    if (type == GameType.truthOrDare) {
      final allowSkip = config?.allowSkip ?? settings?.allowSkip ?? true;
      final enablePunishments =
          config?.enablePunishments ?? settings?.enablePunishments ?? false;
      if (allowSkip && enablePunishments) {
        rules.add((
          Icons.gavel_rounded,
          'Punishment mode is ON — skipping means every other player '
              'submits one punishment and you pick which you\'ll do.',
        ));
      } else if (!enablePunishments) {
        rules.add((
          Icons.block_rounded,
          'Punishment mode is OFF — skipping isn\'t offered as an option.',
        ));
      }

      final policy =
          config?.proofVisibilityPolicy ??
          settings?.proofVisibilityPolicy ??
          'everyone';
      final policyLabel = switch (policy) {
        'players_only' => 'players only',
        'spectators_only' => 'spectators only',
        _ => 'everyone in the game',
      };
      rules.add((
        Icons.visibility_outlined,
        'Proof is visible to: $policyLabel.',
      ));
      final replayMode = config?.proofReplayMode ?? settings?.proofReplayMode;
      rules.add((
        Icons.replay_rounded,
        replayMode == 'replay_once'
            ? 'Proof can be viewed twice (Premium: three times).'
            : 'Proof can be viewed once (Premium: twice).',
      ));
    }

    if (settings != null) {
      if (settings.allowSpectators) {
        rules.add((
          Icons.remove_red_eye_outlined,
          settings.spectatorApprovalRequired
              ? 'Spectators are allowed, subject to host approval.'
              : 'Spectators are allowed to watch freely.',
        ));
      } else {
        rules.add((
          Icons.visibility_off_outlined,
          'Spectators are not allowed in this room.',
        ));
      }
      if (settings.allowSpicy) {
        rules.add((
          Icons.local_fire_department_outlined,
          'Spicy content is enabled for this room.',
        ));
      }
    }

    return rules;
  }
}

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
