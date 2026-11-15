import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/errors/failures.dart';
import '../../../core/utils/app_logger.dart';
import '../../rooms/domain/room_entity.dart';
import '../data/voice_repository.dart';
import '../data/voice_room_adapter.dart';

enum VoiceConnectionStatus {
  idle,
  requestingToken,
  connecting,
  connected,
  reconnecting,
}

/// Why voice is not (or no longer) active — for the future UI to message.
/// Cleared on the next [VoiceRoomController.join].
enum VoiceIssue {
  /// The voice endpoint isn't available on this API (404, not mounted).
  unavailable,

  /// No active membership in this room (absent, left, kicked, definitively
  /// left), or the backend says so (`not_an_active_member`).
  notActiveMember,

  /// Hidden/anonymous spectators can't join voice.
  hiddenSpectator,

  /// Away member waiting for the host to approve their return.
  awaitingApproval,

  /// Explicitly asked for speaker while only allowed to listen.
  speakerNotAllowed,
  bannedFromRoom,
  roomClosed,
  roomNotFound,

  /// Any other 403 from the backend.
  notAllowed,
  rateLimited,
  offline,

  /// Token request, connection or SDK failure.
  failed,

  /// Was a speaker and became a spectator: must rejoin (as listener).
  roleChanged,

  /// Membership became ineligible while connected.
  membershipLost,

  /// Disconnected after 60s in the background.
  backgroundTimeout,

  /// The same account joined voice on another device.
  joinedElsewhere,

  /// Removed by the server or the voice room was deleted.
  removed,

  /// Connection lost after the SDK's own reconnect attempts.
  connectionLost,

  /// Enabling the microphone failed (e.g. OS permission denied).
  microphoneUnavailable,

  /// Voice chat is turned off for this room (room setting, or the server
  /// refused with `voice_disabled`).
  voiceDisabled,
}

/// The only membership facts voice depends on. Built from
/// [RoomMemberEntity]; chat mute (`isMuted`) and game mute (`isGameMuted`)
/// are intentionally not part of it and never affect voice. The admin voice
/// mute (`isVoiceMuted`) is — it only blocks the microphone.
@immutable
class VoiceMembership {
  const VoiceMembership({
    this.isSpectator = false,
    this.isHiddenSpectator = false,
    this.isAway = false,
    this.leftDefinitively = false,
    this.isVoiceMutedByAdmin = false,
  });

  factory VoiceMembership.fromMember(RoomMemberEntity member) =>
      VoiceMembership(
        isSpectator: member.isSpectator,
        isHiddenSpectator: member.isHiddenSpectator,
        isAway: member.isAway,
        leftDefinitively: member.leftDefinitively,
        isVoiceMutedByAdmin: member.isVoiceMuted,
      );

  final bool isSpectator;
  final bool isHiddenSpectator;
  final bool isAway;
  final bool leftDefinitively;
  final bool isVoiceMutedByAdmin;
}

/// Owns at most one LiveKit voice connection for one Jma3a room.
///
/// - Manual mode (no [readVoiceEnabled]): never connects on its own; only
///   [join] starts a connection.
/// - Auto mode ([readVoiceEnabled] given): connects by itself while the room
///   has voice enabled and the member is eligible — but never in the
///   background, and never again on its own after a failure, a server
///   disconnect or a background timeout ([retry] or re-enabling voice for
///   the room clears that). Reconnects always fetch a fresh backend token.
/// - Speakers connect muted; only [setMicrophoneEnabled] turns the mic on.
/// - Membership is observed read-only through [membershipSource] /
///   [readMembership]; voice never writes membership, presence or game state.
/// - Backgrounding mutes immediately and disconnects after
///   [backgroundDisconnectDelay]; resuming cancels that, never unmutes.
/// - Every async step is tied to a generation number, so results that
///   arrive after [leave]/[dispose] (or a newer join) are dropped.
class VoiceRoomController extends ChangeNotifier {
  VoiceRoomController({
    required this.roomId,
    required VoiceRepository repository,
    required Listenable membershipSource,
    required VoiceMembership? Function() readMembership,
    VoiceRoomAdapterFactory? adapterFactory,
    bool Function()? readVoiceEnabled,
    bool observeAppLifecycle = true,
    this.backgroundDisconnectDelay = const Duration(seconds: 60),
  }) : _repository = repository,
       _membershipSource = membershipSource,
       _readMembership = readMembership,
       _readVoiceEnabled = readVoiceEnabled,
       _adapterFactory = adapterFactory ?? LiveKitVoiceRoomAdapter.new {
    _membershipSource.addListener(_onMembershipChanged);
    if (observeAppLifecycle) {
      _lifecycleListener = AppLifecycleListener(
        onStateChange: handleAppLifecycleState,
      );
    }
    if (isAutoMode) {
      _lastVoiceEnabled = isRoomVoiceEnabled;
      _scheduleAutoConnect();
    }
  }

  final String roomId;
  final Duration backgroundDisconnectDelay;
  final VoiceRepository _repository;
  final Listenable _membershipSource;
  final VoiceMembership? Function() _readMembership;
  final bool Function()? _readVoiceEnabled;
  final VoiceRoomAdapterFactory _adapterFactory;
  AppLifecycleListener? _lifecycleListener;

  VoiceRoomAdapter? _adapter;
  StreamSubscription<VoiceRoomEvent>? _eventsSub;
  Timer? _backgroundTimer;
  int _generation = 0;
  bool _disposed = false;
  bool _inBackground = false;

  VoiceConnectionStatus _status = VoiceConnectionStatus.idle;
  VoiceRole? _role;
  Set<String> _activeSpeakerIds = const {};
  VoiceIssue? _issue;

  // Microphone: what the user asked for vs. what the adapter last confirmed.
  // _syncMicrophone() reconciles the two one call at a time, so a mute (user
  // or background) issued while an enable is still in flight always wins.
  bool _micDesired = false;
  bool _micActual = false;
  Future<void>? _micSync; // the running reconcile loop, shared by waiters

  // Outstanding [VoiceMicrophoneHold]s (e.g. a voice-proof recording). While
  // any exist the mic can't be enabled; releasing one never re-enables it.
  int _micHolds = 0;

  // Adapter teardowns still in flight, so a hold taken right after leaving
  // voice waits until LiveKit has actually released the microphone.
  final Set<Future<void>> _pendingDisposals = {};

  // Auto mode: suppressed after failures/background so it never loops or
  // reconnects behind the user's back; cleared by retry() or by the room's
  // voice being switched off and on again.
  bool _autoSuppressed = false;
  bool _autoScheduled = false;
  bool _lastVoiceEnabled = false;

  // Whether the SERVER currently lets this participant publish: from the
  // token grant, then from LiveKit permission updates (admin mute/unmute,
  // demotion). The client never assumes more than this.
  bool _serverCanPublish = false;

  VoiceConnectionStatus get status => _status;

  /// Granted role while a session exists; null when idle.
  VoiceRole? get role => _role;

  /// True only once the adapter confirmed the mic is on and the user still
  /// wants it on; a mute is reflected immediately.
  bool get isMicrophoneEnabled => _micDesired && _micActual;
  Set<String> get activeSpeakerIds => _activeSpeakerIds;
  VoiceIssue? get issue => _issue;
  bool get isDisposed => _disposed;
  bool get isInBackground => _inBackground;

  bool get isActive => _status != VoiceConnectionStatus.idle;

  bool get isAutoMode => _readVoiceEnabled != null;

  /// The room's voice switch (always true in manual mode).
  bool get isRoomVoiceEnabled => _readVoiceEnabled?.call() ?? true;

  /// Auto mode only: true when automatic connection is paused until [retry].
  bool get isAutoConnectSuppressed => _autoSuppressed;

  bool get _adminMuted => _readMembership()?.isVoiceMutedByAdmin ?? false;

  /// Admin voice mute in effect — from the membership row, or because the
  /// server is currently refusing this speaker publish rights.
  bool get isVoiceMutedByAdmin =>
      _adminMuted ||
      (_status == VoiceConnectionStatus.connected &&
          _role == VoiceRole.speaker &&
          !_serverCanPublish);

  bool get canToggleMicrophone =>
      _status == VoiceConnectionStatus.connected &&
      _role == VoiceRole.speaker &&
      _serverCanPublish &&
      !_adminMuted &&
      !_inBackground &&
      _micHolds == 0;

  /// True while something else (voice-proof recording) owns the microphone.
  bool get isMicrophoneHeld => _micHolds > 0;

  /// Local pre-check mirroring the backend's rules, so obviously ineligible
  /// users never call the endpoint. The backend remains authoritative.
  VoiceIssue? get joinBlocker => _eligibilityIssue(_readMembership());

  /// Current membership facts (read-only), e.g. for the UI to keep mic
  /// controls away from spectators regardless of session state.
  VoiceMembership? get membership => _readMembership();

  // ── Join / leave ────────────────────────────────────────────────────────

  Future<void> join() async {
    if (_disposed || _status != VoiceConnectionStatus.idle) return;

    if (!isRoomVoiceEnabled) {
      _issue = VoiceIssue.voiceDisabled;
      _notify();
      return;
    }

    final blocker = joinBlocker;
    if (blocker != null) {
      _issue = blocker;
      _notify();
      return;
    }

    final gen = ++_generation;
    _issue = null;
    _status = VoiceConnectionStatus.requestingToken;
    _notify();

    final VoiceTokenGrant grant;
    try {
      grant = await _repository.fetchToken(roomId: roomId);
    } on Failure catch (f) {
      if (gen != _generation) return;
      _endSession(_issueForFailure(f), suppress: true);
      return;
    } catch (e) {
      if (gen != _generation) return;
      AppLogger.warning('Voice: token request failed (${e.runtimeType})');
      _endSession(VoiceIssue.failed, suppress: true);
      return;
    }
    if (gen != _generation) return;

    // Membership may have changed while the token was in flight.
    final lateBlocker = _sessionIssue(_readMembership(), grant.role);
    if (lateBlocker != null) {
      _endSession(lateBlocker);
      return;
    }

    final adapter = _adapterFactory();
    _adapter = adapter;
    _eventsSub = adapter.events.listen((event) => _onRoomEvent(gen, event));
    _role = grant.role;
    _serverCanPublish = grant.role == VoiceRole.speaker && !grant.voiceMuted;
    _status = VoiceConnectionStatus.connecting;
    _notify();

    try {
      await adapter.connect(url: grant.livekitUrl, token: grant.token);
    } catch (e) {
      if (gen != _generation) return;
      AppLogger.warning('Voice: connect failed (${e.runtimeType})');
      _endSession(VoiceIssue.failed, suppress: true);
      return;
    }
    if (gen != _generation) return;

    _status = VoiceConnectionStatus.connected;
    AppLogger.info('Voice: connected room=$roomId role=${grant.role.name}');
    _notify();

    // Backgrounded mid-join: keep the timer already counting from the moment
    // the app went to background; only start one if none is pending.
    if (_inBackground && _backgroundTimer == null) {
      _scheduleBackgroundDisconnect();
    }
  }

  /// Leaves voice and releases audio resources. Idempotent. In auto mode
  /// this also pauses automatic connection until [retry].
  Future<void> leave() async {
    if (_disposed) return;
    _endSession(null, suppress: true);
  }

  /// Safe retry after an automatic connection failed or was paused: clears
  /// the pause and the last issue, then connects (if still eligible).
  Future<void> retry() async {
    if (_disposed) return;
    _autoSuppressed = false;
    _issue = null;
    _notify();
    await join();
  }

  void _scheduleAutoConnect() {
    if (!isAutoMode || _disposed || _autoScheduled) return;
    _autoScheduled = true;
    scheduleMicrotask(() {
      _autoScheduled = false;
      if (_disposed ||
          _status != VoiceConnectionStatus.idle ||
          _inBackground ||
          _autoSuppressed ||
          !isRoomVoiceEnabled ||
          joinBlocker != null) {
        return;
      }
      unawaited(join());
    });
  }

  // ── Microphone ──────────────────────────────────────────────────────────

  /// The only way the microphone is ever turned on. Ignored unless connected
  /// as a speaker in the foreground.
  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (_disposed) return;
    if (enabled && !canToggleMicrophone) return;
    if (_micDesired == enabled) return;
    _micDesired = enabled;
    _notify();
    await _syncMicrophone();
  }

  bool get _micAllowed =>
      _micDesired &&
      _serverCanPublish &&
      !_adminMuted &&
      !_inBackground &&
      _micHolds == 0 &&
      _role == VoiceRole.speaker &&
      (_status == VoiceConnectionStatus.connected ||
          _status == VoiceConnectionStatus.reconnecting);

  /// Starts the reconcile loop, or joins the one already running (which
  /// re-reads the target every iteration, so it picks up the new state).
  Future<void> _syncMicrophone() {
    final running = _micSync;
    if (running != null) return running;
    final adapter = _adapter;
    if (adapter == null) return Future.value();
    final loop = _runMicrophoneSync(adapter);
    _micSync = loop;
    loop.whenComplete(() {
      if (identical(_micSync, loop)) _micSync = null;
    });
    return loop;
  }

  Future<void> _runMicrophoneSync(VoiceRoomAdapter adapter) async {
    final gen = _generation;
    try {
      while (gen == _generation && !_disposed) {
        final target = _micAllowed;
        if (target == _micActual) break;
        try {
          await adapter.setMicrophoneEnabled(target);
          if (gen != _generation || _disposed) break;
          _micActual = target;
        } catch (e) {
          if (gen != _generation || _disposed) break;
          AppLogger.warning(
            'Voice: microphone toggle failed (${e.runtimeType})',
          );
          if (!target) {
            // Couldn't confirm a mute: fail closed rather than risk a live
            // mic the UI shows as muted. Teardown disables it.
            _endSession(VoiceIssue.failed, suppress: true);
            return;
          }
          _micDesired = false;
          _issue = VoiceIssue.microphoneUnavailable;
          break;
        }
      }
    } finally {
      if (gen == _generation && !_disposed) _notify();
    }
  }

  // ── Microphone holds (voice-proof recording) ────────────────────────────

  /// How long [holdMicrophoneOff] waits for LiveKit to confirm the mute.
  static const microphoneHoldTimeout = Duration(seconds: 3);

  /// Mutes the voice mic and keeps it muted until the returned hold is
  /// released, so another recorder can use the microphone. Returns null if
  /// the mute could not be confirmed within [timeout] (or the session ended
  /// while muting): the caller must not start recording then.
  ///
  /// Releasing the hold never unmutes — the user re-enables the mic
  /// explicitly. With no voice session the hold is granted immediately
  /// (after any in-flight teardown has finished).
  Future<VoiceMicrophoneHold?> holdMicrophoneOff({
    Duration timeout = microphoneHoldTimeout,
  }) async {
    if (_disposed) {
      return await _awaitPendingDisposals(timeout)
          ? VoiceMicrophoneHold._(null)
          : null;
    }
    _micHolds++;
    final hold = VoiceMicrophoneHold._(this);
    _micDesired = false;
    _notify();

    if (!isActive) {
      if (await _awaitPendingDisposals(timeout)) return hold;
      hold.release();
      return null;
    }

    final gen = _generation;
    try {
      await _syncMicrophone().timeout(timeout);
    } on TimeoutException {
      AppLogger.warning('Voice: mute for recording not confirmed in time');
      hold.release();
      return null;
    }
    if (_disposed) return hold; // adapter torn down with the controller
    if (gen != _generation || _micActual) {
      // Session ended mid-mute (e.g. failed mute -> fail closed) or the mic
      // is still reported on: not provably free.
      hold.release();
      return null;
    }
    return hold;
  }

  Future<bool> _awaitPendingDisposals(Duration timeout) async {
    if (_pendingDisposals.isEmpty) return true;
    try {
      await Future.wait(_pendingDisposals.toList()).timeout(timeout);
      return true;
    } on TimeoutException {
      return false;
    }
  }

  void _releaseHold() {
    if (_micHolds > 0) _micHolds--;
    _notify(); // never re-enables the mic
  }

  // ── App lifecycle ───────────────────────────────────────────────────────

  @visibleForTesting
  void handleAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (_inBackground) return;
        _inBackground = true;
        // Resuming must never reconnect automatically.
        if (isAutoMode) _autoSuppressed = true;
        _micDesired = false; // mute now; never restored automatically
        unawaited(_syncMicrophone());
        if (isActive) _scheduleBackgroundDisconnect();
        _notify();
      case AppLifecycleState.resumed:
        if (!_inBackground) return;
        _inBackground = false;
        _backgroundTimer?.cancel();
        _backgroundTimer = null;
        _notify(); // never unmutes, never reconnects
      case AppLifecycleState.detached:
        _endSession(null);
      case AppLifecycleState.inactive:
        break; // transient (control center, incoming call sheet)
    }
  }

  void _scheduleBackgroundDisconnect() {
    _backgroundTimer?.cancel();
    final gen = _generation;
    _backgroundTimer = Timer(backgroundDisconnectDelay, () {
      if (_disposed || gen != _generation || !_inBackground) return;
      AppLogger.info('Voice: disconnected after background timeout');
      _endSession(VoiceIssue.backgroundTimeout, suppress: true);
    });
  }

  // ── Membership ──────────────────────────────────────────────────────────

  /// Reacts to RoomProvider changes (membership AND room settings).
  void _onMembershipChanged() {
    if (_disposed) return;

    if (isAutoMode) {
      final enabled = isRoomVoiceEnabled;
      if (enabled != _lastVoiceEnabled) {
        _lastVoiceEnabled = enabled;
        if (enabled) {
          // A fresh enable is a fresh chance: clear any earlier pause.
          _autoSuppressed = false;
          if (_issue == VoiceIssue.voiceDisabled) _issue = null;
          _notify();
        }
      }
      if (!enabled) {
        if (isActive) {
          AppLogger.info('Voice: room voice disabled, leaving voice');
          _endSession(VoiceIssue.voiceDisabled);
        }
        return;
      }
    }

    if (isActive) {
      final issue = _sessionIssue(_readMembership(), _role);
      if (issue != null) {
        AppLogger.info('Voice: membership changed, leaving voice ($issue)');
        _endSession(issue); // eligibility-driven: auto mode may rejoin below
      } else if (_adminMuted && (_micDesired || _micActual)) {
        _micDesired = false; // admin mute wins over the local toggle
        unawaited(_syncMicrophone());
        _notify();
      }
    }
    _scheduleAutoConnect();
  }

  static VoiceIssue? _eligibilityIssue(VoiceMembership? m) {
    if (m == null || m.leftDefinitively) return VoiceIssue.notActiveMember;
    if (m.isHiddenSpectator) return VoiceIssue.hiddenSpectator;
    if (m.isAway) return VoiceIssue.awaitingApproval;
    return null;
  }

  /// Eligibility for an existing session: membership must still be valid,
  /// and a speaker token is void once the member becomes a spectator.
  static VoiceIssue? _sessionIssue(VoiceMembership? m, VoiceRole? role) {
    final issue = _eligibilityIssue(m);
    if (issue != null) {
      return issue == VoiceIssue.notActiveMember
          ? VoiceIssue.membershipLost
          : issue;
    }
    if (role == VoiceRole.speaker && m!.isSpectator) {
      return VoiceIssue.roleChanged;
    }
    return null;
  }

  // ── Room events ─────────────────────────────────────────────────────────

  void _onRoomEvent(int gen, VoiceRoomEvent event) {
    if (_disposed || gen != _generation) return;
    switch (event) {
      case VoiceReconnecting():
        if (_status == VoiceConnectionStatus.connected) {
          _status = VoiceConnectionStatus.reconnecting;
          _notify();
        }
      case VoiceReconnected():
        if (_status == VoiceConnectionStatus.reconnecting) {
          _status = VoiceConnectionStatus.connected;
          _notify();
        }
      case VoiceDisconnected(:final reason):
        if (reason == VoiceDisconnectReason.clientInitiated) return;
        _endSession(switch (reason) {
          VoiceDisconnectReason.duplicateIdentity => VoiceIssue.joinedElsewhere,
          VoiceDisconnectReason.removed => VoiceIssue.removed,
          _ => VoiceIssue.connectionLost,
        }, suppress: true);
      case VoiceActiveSpeakersChanged(:final identities):
        _activeSpeakerIds = Set.unmodifiable(identities);
        _notify();
      case VoiceLocalPublishPermissionChanged(:final canPublish):
        _serverCanPublish = canPublish;
        if (!canPublish) {
          // The server unpublished us; don't try to republish.
          _micDesired = false;
          _micActual = false;
        }
        _notify(); // granting publish never turns the mic on by itself
    }
  }

  // ── Teardown ────────────────────────────────────────────────────────────

  /// Synchronously returns to idle (so the UI never shows a dead session)
  /// and releases the adapter in the background. Bumping the generation
  /// invalidates every in-flight await and timer of the old session.
  void _endSession(VoiceIssue? issue, {bool suppress = false}) {
    _generation++;
    if (suppress && isAutoMode) _autoSuppressed = true;
    _serverCanPublish = false;
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    final sub = _eventsSub;
    final adapter = _adapter;
    _eventsSub = null;
    _adapter = null;
    sub?.cancel();
    if (adapter != null) {
      final disposal = _disposeAdapter(adapter);
      _pendingDisposals.add(disposal);
      unawaited(
        disposal.whenComplete(() => _pendingDisposals.remove(disposal)),
      );
    }

    final changed = _status != VoiceConnectionStatus.idle || issue != _issue;
    _status = VoiceConnectionStatus.idle;
    _role = null;
    _micDesired = false;
    _micActual = false;
    _micSync = null;
    _activeSpeakerIds = const {};
    if (issue != null) _issue = issue;
    if (changed) _notify();
  }

  static Future<void> _disposeAdapter(VoiceRoomAdapter adapter) async {
    try {
      await adapter.dispose();
    } catch (e) {
      AppLogger.warning('Voice: adapter cleanup failed (${e.runtimeType})');
    }
  }

  static VoiceIssue _issueForFailure(Failure f) => switch (f) {
    ForbiddenFailure(:final code) => switch (code) {
      'speaker_not_allowed' => VoiceIssue.speakerNotAllowed,
      'banned_from_room' => VoiceIssue.bannedFromRoom,
      'room_closed' => VoiceIssue.roomClosed,
      'voice_disabled' => VoiceIssue.voiceDisabled,
      'not_an_active_member' ||
      'profile_unavailable' => VoiceIssue.notActiveMember,
      _ => VoiceIssue.notAllowed,
    },
    NotFoundFailure(:final code) =>
      code == 'room_not_found'
          ? VoiceIssue.roomNotFound
          : VoiceIssue.unavailable,
    RateLimitFailure() => VoiceIssue.rateLimited,
    OfflineFailure() || NetworkFailure() => VoiceIssue.offline,
    _ => VoiceIssue.failed,
  };

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true; // first: teardown below must not notify listeners
    _endSession(null);
    _membershipSource.removeListener(_onMembershipChanged);
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
    super.dispose();
  }
}

/// A claim on the microphone from [VoiceRoomController.holdMicrophoneOff].
/// [release] is idempotent and never turns the voice mic back on.
class VoiceMicrophoneHold {
  VoiceMicrophoneHold._(this._controller);

  final VoiceRoomController? _controller;
  bool _released = false;

  bool get isReleased => _released;

  void release() {
    if (_released) return;
    _released = true;
    _controller?._releaseHold();
  }
}
