/// Shared across ToD/NHIE/Meme's providers and screens: the exact message
/// used whenever a reconnect/DB-fallback discovers the session was
/// deliberately closed elsewhere (auto-end, host-disconnect timeout, quit)
/// rather than found genuinely missing/broken. Screens compare against this
/// constant (not just checking loadState == error) to auto-navigate to the
/// lobby instead of showing a dead-end error screen — see each screen's
/// error-state branch.
const String kSessionEndedErrorMessage =
    'This game has ended. Please return to the lobby.';
