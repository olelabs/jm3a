/// Single-flight runner with at most one trailing run.
///
/// [request] starts [_task] if nothing is running. While a run is in
/// flight, any number of further requests collapse into ONE trailing run
/// that starts the moment the current one finishes (with the most recently
/// requested argument) — so a burst of triggers costs one current run plus
/// one trailing run, never one run per trigger, and the last request is
/// always followed by a run that started after it (no update is lost).
///
/// The Future returned by [request] completes once the run that will
/// reflect that request has finished (the current run, or the trailing run
/// for a request made mid-flight). A throwing task is reported to
/// [onError] and never leaves the runner stuck: the next request starts a
/// fresh run.
class CoalescedRunner<T> {
  CoalescedRunner(this._task, {void Function(Object error, StackTrace st)? onError})
      : _onError = onError;

  final Future<void> Function(T arg) _task;
  final void Function(Object error, StackTrace st)? _onError;

  Future<void>? _inFlight;
  bool _trailingRequested = false;
  late T _latestArg;

  bool get isRunning => _inFlight != null;

  Future<void> request(T arg) {
    _latestArg = arg;
    final current = _inFlight;
    if (current != null) {
      _trailingRequested = true;
      return current;
    }
    return _inFlight = _drain();
  }

  Future<void> _drain() async {
    try {
      do {
        _trailingRequested = false;
        try {
          await _task(_latestArg);
        } catch (e, st) {
          _onError?.call(e, st);
        }
      } while (_trailingRequested);
    } finally {
      _inFlight = null;
    }
  }
}
