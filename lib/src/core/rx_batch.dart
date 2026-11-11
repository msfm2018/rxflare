import 'rx_state.dart';

/// Internal batching / untracked control for RxFlare.
///
/// - [batch] groups multiple state writes so listeners are notified once
///   after the outermost batch ends (merges updates that would otherwise
///   trigger multiple rebuilds under synchronous [setState]).
/// - [untracked] runs a function without registering reactive dependencies
///   on the current [RxStack] context.
class RxBatch {
  static int _depth = 0;
  /// States that had a full-value write in this batch.
  static final Set<RxState> _pendingGlobal = {};
  /// Field-level writes: state → fields.
  static final Map<RxState, Set<dynamic>> _pendingFields = {};
  static bool _untrackedDepth = false;

  /// Whether we are currently inside a [batch] scope.
  static bool get isBatching => _depth > 0;

  /// Whether dependency tracking is currently suppressed.
  static bool get isUntracked => _untrackedDepth;

  /// Runs [fn] while suppressing automatic dependency registration.
  ///
  /// Useful when reading reactive values for logging, side effects, or
  /// conditional logic that should not create a reactive subscription.
  ///
  /// Example:
  /// ```dart
  /// final snapshot = untracked(() => count.value);
  /// ```
  static T untracked<T>(T Function() fn) {
    final prev = _untrackedDepth;
    _untrackedDepth = true;
    try {
      return fn();
    } finally {
      _untrackedDepth = prev;
    }
  }

  /// Runs [fn] inside a batch. Nested batches are supported; notifications
  /// are flushed only when the outermost batch completes.
  ///
  /// Example:
  /// ```dart
  /// batch(() {
  ///   a.value = 1;
  ///   b.value = 2;
  ///   c.value = 3;
  /// }); // listeners notified once
  /// ```
  static T batch<T>(T Function() fn) {
    _depth++;
    try {
      return fn();
    } finally {
      _depth--;
      if (_depth == 0) {
        _flush();
      }
    }
  }

  /// Called by [RxState] when a global (non-field) change occurs.
  static void scheduleState(RxState state) {
    if (_depth > 0) {
      _pendingGlobal.add(state);
      return;
    }
    state.notifyListenersNow();
  }

  /// Called by [RxState] when a field-level change occurs.
  static void scheduleField(RxState state, dynamic field) {
    if (_depth > 0) {
      _pendingFields.putIfAbsent(state, () => <dynamic>{}).add(field);
      return;
    }
    state.notifyFieldNow(field);
  }

  static void _flush() {
    final globals = Set<RxState>.from(_pendingGlobal);
    final fields = Map<RxState, Set<dynamic>>.from(
      _pendingFields.map((k, v) => MapEntry(k, Set<dynamic>.from(v))),
    );
    _pendingGlobal.clear();
    _pendingFields.clear();

    // Field notifications first (more specific).
    fields.forEach((state, fieldSet) {
      if (state.isDisposed) return;
      for (final f in fieldSet) {
        state.notifyFieldNow(f);
      }
    });

    // Global notifications once per state that had a full-value write.
    for (final state in globals) {
      if (state.isDisposed) continue;
      state.notifyListenersNow();
    }
  }
}

/// Runs [fn] without registering reactive dependencies.
///
/// See [RxBatch.untracked].
T untracked<T>(T Function() fn) => RxBatch.untracked(fn);

/// Groups multiple reactive writes so listeners fire once at the end.
///
/// See [RxBatch.batch].
T batch<T>(T Function() fn) => RxBatch.batch(fn);
