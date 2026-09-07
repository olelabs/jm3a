import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import 'game_card_background.dart';

/// A read-only, provider-free "what will this look like in the game" card
/// face — used by the pack-creation flow (cover step + card step) so a
/// creator can see an approximation of the real NHIE/Meme/ToD card face
/// before publishing, without depending on any live GameProvider/engine.
///
/// Deliberately NOT the same widget class as the actual game screens' own
/// `_NhieCardFace`/`_MemeCardFace`/ToD `_CardFace` — those are private,
/// tightly coupled to live round state, and animate on round-change, none
/// of which applies to a static creator preview. What IS shared, and must
/// stay shared, is the background-image fallback chain: this widget
/// resolves its background through the exact same [GameCardBackground]
/// the real card faces use, so "what the creator sees" and "what players
/// see" can never silently diverge.
class GameCardPreview extends StatelessWidget {
  const GameCardPreview({
    super.key,
    required this.gameType,
    required this.content,
    this.cardTypeIsDare = false,
    this.isSpicy = false,
    this.imageUrl,
  });

  /// Raw pack game-type string: 'truth_or_dare' | 'never_have_i_ever' |
  /// 'meme_game' — the same values PackDraft.gameType already uses.
  final String gameType;
  final String content;

  /// Only meaningful for truth_or_dare — selects the Truth/Dare badge and
  /// accent color. Ignored for every other game type.
  final bool cardTypeIsDare;
  final bool isSpicy;

  /// Resolution order already applied by the caller: a card-specific
  /// image if the card has one, else the pack's own cover. This widget
  /// only adds the final two fallback steps (default asset, flat color)
  /// via [GameCardBackground].
  final String? imageUrl;

  static const _kNhieVivid = Color(0xFF0EA37A);
  static const _kNhieDeep = Color(0xFF065F46);
  static const _kMemeVivid = Color(0xFFF59E0B);
  static const _kMemeDeep = Color(0xFF92400E);
  static const _kTruthColor = Color(0xFF3B82F6);
  static const _kDareColor = Color(0xFFEF4444);
  static const _kSpicyColor = Color(0xFFEA580C);

  @override
  Widget build(BuildContext context) {
    final (accent, deep, badgeLabel, badgeEmoji) = switch (gameType) {
      'never_have_i_ever' => (
        _kNhieVivid,
        _kNhieDeep,
        context.l10n.nhieBadgeAllCaps,
        '🙊',
      ),
      'meme_game' => (_kMemeVivid, _kMemeDeep, context.l10n.memeBadgeAllCaps, '😂'),
      _ => cardTypeIsDare
          ? (_kDareColor, const Color(0xFFB91C1C), context.l10n.todDareBadge, '🔥')
          : (_kTruthColor, const Color(0xFF1D4ED8), context.l10n.todTruthBadge, '🤔'),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.28),
                  blurRadius: 28,
                  spreadRadius: -4,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: GameCardBackground(imageUrl: imageUrl, fallbackColor: deep),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          deep.withValues(alpha: 0.48),
                          const Color(0xFF0D1B2A).withValues(alpha: 0.68),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0x22FFFFFF), Color(0x00FFFFFF)],
                          stops: [0.0, 0.5],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(constraints.maxWidth < 220 ? 16 : 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(badgeEmoji, style: const TextStyle(fontSize: 12)),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      badgeLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: constraints.maxWidth < 160 ? 8 : 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isSpicy) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _kSpicyColor.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                '🌶',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Text(
                              content.isEmpty ? '…' : content,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: constraints.maxWidth < 220 ? 15 : 18,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                                shadows: const [
                                  Shadow(color: Colors.black54, blurRadius: 8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
