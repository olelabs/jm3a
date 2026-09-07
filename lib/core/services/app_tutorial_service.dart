import '../storage/local_storage_service.dart';

/// Canonical ids for every first-time tutorial in the app. Kept as plain
/// string constants (not an enum) so they double as the stable persistence
/// keys — renaming one would only ever *re-show* that single tutorial, never
/// corrupt the others.
class TutorialIds {
  TutorialIds._();

  /// Full-screen first-launch product tour. NOT owned by this service's own
  /// storage — it is the pre-existing [IntroScreen], gated by the legacy
  /// `has_seen_intro` flag in AppRouter's redirect. Bridged in here so it
  /// participates in the unified "completed?" / resetAll() model without
  /// duplicating that screen or its flag. See [AppTutorialService].
  static const appIntro = 'app_intro';

  static const homeIntro = 'home_intro';
  static const roomBrowserIntro = 'room_browser_intro';
  static const roomCreationIntro = 'room_creation_intro';
  static const roomLobbyIntro = 'room_lobby_intro';
  static const roomMembersIntro = 'room_members_intro';
  static const todIntro = 'tod_intro';
  static const nhieIntro = 'nhie_intro';
  static const memeIntro = 'meme_intro';
  static const profileIntro = 'profile_intro';
  static const settingsIntro = 'settings_intro';

  /// Every id, used by [AppTutorialService.resetAll].
  static const all = <String>[
    appIntro,
    homeIntro,
    roomBrowserIntro,
    roomCreationIntro,
    roomLobbyIntro,
    roomMembersIntro,
    todIntro,
    nhieIntro,
    memeIntro,
    profileIntro,
    settingsIntro,
  ];
}

/// Central authority for first-time / contextual tutorials.
///
/// Single responsibility: decide whether a given tutorial should run, remember
/// that it has been completed (locally, per device — no DB table, no server
/// state), and guard against a tutorial being launched twice at once. It owns
/// NO UI and touches NO Provider, realtime, game, or navigation state — the
/// [ScreenTutorial] widget drives the actual overlay and simply asks this
/// service the yes/no questions. This keeps tutorials completely orthogonal to
/// the multiplayer/game lifecycle.
///
/// Persistence reuses the existing [LocalStorageService] (a thin
/// SharedPreferences wrapper initialized at startup) — a single string-list of
/// completed ids under [_completedKey]. The one exception is [TutorialIds.
/// appIntro], which is bridged to the pre-existing `has_seen_intro` flag so the
/// existing [IntroScreen] / router redirect remain the single source of truth
/// for the first-launch tour (no duplicate intro system).
class AppTutorialService {
  AppTutorialService._();
  static final AppTutorialService _instance = AppTutorialService._();
  static AppTutorialService get instance => _instance;

  static const _completedKey = 'tutorials_completed_v1';

  /// Legacy flag owned by [IntroScreen] / AppRouter — reused, not replaced, so
  /// app_intro has exactly one source of truth.
  static const _legacyIntroKey = 'has_seen_intro';

  LocalStorageService get _store => LocalStorageService.instance;

  /// Ids currently mid-showcase, so a rebuild / re-entry can't start the same
  /// tour twice on top of itself. In-memory only (a fresh launch clears it).
  final Set<String> _active = <String>{};

  Set<String> _completed() =>
      (_store.getStringList(_completedKey) ?? const <String>[]).toSet();

  /// Whether [id] has already been completed (or, for app_intro, whether the
  /// existing intro flag is set).
  bool isCompleted(String id) {
    if (id == TutorialIds.appIntro) {
      return _store.getBool(_legacyIntroKey) ?? false;
    }
    return _completed().contains(id);
  }

  /// Whether the tutorial for [id] should run right now: not already completed
  /// AND not already on screen. This is the ONLY gate [ScreenTutorial] needs;
  /// callers must still confirm the target widgets actually exist.
  bool shouldShow(String id) => !isCompleted(id) && !_active.contains(id);

  /// Reserve [id] as the active tour. Returns false if it is already running,
  /// so the caller can abort a duplicate start. Pair every true result with a
  /// later [endShowing].
  bool beginShowing(String id) {
    if (_active.contains(id)) return false;
    _active.add(id);
    return true;
  }

  void endShowing(String id) => _active.remove(id);

  /// Persist [id] as completed (idempotent) and release its active lock. For
  /// app_intro this writes the legacy flag so the router stops showing it.
  Future<void> markCompleted(String id) async {
    _active.remove(id);
    if (id == TutorialIds.appIntro) {
      await _store.setBool(_legacyIntroKey, true);
      return;
    }
    final set = _completed()..add(id);
    await _store.setStringList(_completedKey, set.toList());
  }

  /// Re-enable a single tutorial so it shows again on next entry.
  Future<void> resetTutorial(String id) async {
    _active.remove(id);
    if (id == TutorialIds.appIntro) {
      await _store.remove(_legacyIntroKey);
      return;
    }
    final set = _completed()..remove(id);
    await _store.setStringList(_completedKey, set.toList());
  }

  /// Re-enable every tutorial (used by the Settings "replay tutorials" action
  /// and for QA). Clears both this service's list and the legacy intro flag.
  Future<void> resetAll() async {
    _active.clear();
    await _store.remove(_completedKey);
    await _store.remove(_legacyIntroKey);
  }
}
