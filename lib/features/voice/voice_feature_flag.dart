/// Master switch for LiveKit voice chat in this app version.
///
/// Voice chat is temporarily deactivated: the full implementation stays in
/// `lib/features/voice/` (and the backend), but while this is `false` the
/// app never shows any voice UI and the lobby's `VoiceRoomController` treats
/// the room's voice as off, so it never requests a token, connects to
/// LiveKit or touches the microphone — even for rooms whose
/// `room_settings.voice_enabled` is already true.
///
/// To reactivate voice chat, set this to `true`.
const bool kVoiceChatEnabled = false;
