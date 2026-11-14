import 'dart:async';

/// Serializes immutable draft snapshots. A failed write remains dirty for retry;
/// a newer edit made during a write is saved before flush completes.
class DraftSaveController<T> {
  DraftSaveController({
    required this.write,
    required this.onChanged,
    this.delay = const Duration(milliseconds: 500),
  });

  final Future<void> Function(T snapshot) write;
  final void Function() onChanged;
  final Duration delay;
  Timer? _timer;
  Future<bool>? _pending;
  T? _snapshot;
  int _revision = 0;
  int _savedRevision = 0;
  bool _disposed = false;
  Object? error;

  bool get isDirty => _savedRevision != _revision;
  bool get isSaving => _pending != null;

  void update(T snapshot) {
    _snapshot = snapshot;
    _revision++;
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(flush()));
    _notify();
  }

  Future<bool> flush() {
    _timer?.cancel();
    final pending = _pending;
    if (pending != null) return pending;
    if (!isDirty) return Future.value(true);
    // Schedule the body after assigning _pending, including synchronously
    // throwing repository implementations.
    final result = Future<bool>.microtask(_writeLatest);
    _pending = result.whenComplete(() {
      _pending = null;
      _notify();
    });
    _notify();
    return _pending!;
  }

  Future<bool> _writeLatest() async {
    while (isDirty) {
      final revision = _revision;
      final snapshot = _snapshot as T;
      try {
        await write(snapshot);
        _savedRevision = revision;
        error = null;
      } catch (failure) {
        error = failure;
        return false;
      }
    }
    return true;
  }

  void _notify() {
    if (!_disposed) onChanged();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }
}
