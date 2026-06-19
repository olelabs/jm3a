import 'base_game_engine.dart';
import '../truth_or_dare/truth_or_dare_engine.dart';
import '../never_have_i_ever/never_have_i_ever_engine.dart';
import '../meme_game/meme_game_engine.dart';

/// Maps GameType → engine factory.
/// GameConfig is defined in base_game_engine.dart — do NOT redefine here.
/// Adding a new game = one new entry. No changes to GameProvider or routing.
final gameRegistry = <GameType, BaseGameEngine Function(GameConfig, List<dynamic>)>{
  GameType.truthOrDare:    (cfg, cards) => TruthOrDareEngine(cfg,
      cards: cards.cast()),
  GameType.neverHaveIEver: (cfg, cards) => NeverHaveIEverEngine(cfg,
      cards: cards.cast()),
  GameType.memeGame:       (cfg, prompts) => MemeGameEngine(cfg,
      prompts: prompts.cast()),
};
