import 'rx_stack.dart';
import '../utils/rx_debug.dart';
import 'base_.dart';
import 'rx_state.dart';

/// Evaluates the initial computed value while collecting its dependencies.
///
/// This is kept outside [RxComputed] so the public generative constructor can
/// redirect to a private generative constructor without evaluating [compute]
/// more than once.
_RxComputedInitial<T> _evaluateInitial<T>(T Function() compute) {
  final context = RxContext();

  RxStack.push(context);
  try {
    return _RxComputedInitial<T>(compute(), context);
  } finally {
    RxStack.pop();
  }
}

/// Holds the initial value and the dependencies collected while computing it.
class _RxComputedInitial<T> {
  final T value;
  final RxContext context;

  const _RxComputedInitial(this.value, this.context);
}

/// Creates a computed reactive value.
RxComputed<T> computed<T>(T Function() fn) => RxComputed<T>(fn);

/// A reactive computed value that automatically tracks dependencies.
///
/// `RxComputed` automatically re-evaluates when any of its dependent
/// `RxState` or field-level dependencies change.
///
/// Features:
/// - Automatic dependency tracking (state + field-level)
/// - Lazy recomputation on dependency change
/// - Read-only reactive value (cannot be set manually)
///
/// ```dart
/// final a = RxState<int>(1);
/// final b = RxState<int>(2);
/// final sum = RxComputed<int>(() => a.value + b.value);
///
/// sum.listen((val) => print('sum = $val'));
/// a.value = 3; // sum = 5
/// ```
class RxComputed<T> extends RxState<T> {
  /// The computation function used to derive the value.
  final T Function() compute;

  /// Set of dependent reactive states.
  final Set<RxState> _deps = {};

  /// Field-level dependency tracking per state.
  final Map<RxState, Set<dynamic>> _fieldDeps = {};

  /// Prevents recursive recomputation loops.
  bool _computing = false;

  /// Creates a computed reactive value.
  ///
  /// The initial value is evaluated immediately and its dependencies are
  /// collected during that same evaluation.
  RxComputed(T Function() compute) : this._(compute, _evaluateInitial(compute));

  RxComputed._(this.compute, _RxComputedInitial<T> initial)
      : super(initial.value) {
    _updateDeps(initial.context);
    RxDebug.log(" RxComputed(id: $id) 初始化完成");
  }

  // =========================
  // Core recomputation logic
  // =========================

  void _updateValueAndDeps() {
    if (_computing || isDisposed) return;

    _computing = true;
    final context = RxContext();

    try {
      RxStack.push(context);

      final newValue = compute();

      _updateDeps(context);
      internalUpdate(newValue);
    } finally {
      RxStack.pop();
      _computing = false;
    }
  }

  // =========================
  // Dependency diffing system
  // =========================

  void _updateDeps(RxContext context) {
    final newStates = context.states;
    final newFields = context.fields;

    // Remove stale state dependencies.
    for (final dependency in _deps.difference(newStates)) {
      dependency.removeListener(_refresh);
    }

    // Add newly observed state dependencies.
    for (final dependency in newStates.difference(_deps)) {
      dependency.addListener(_refresh);
    }

    _deps
      ..clear()
      ..addAll(newStates);

    // Remove stale field-level dependencies.
    _fieldDeps.forEach((state, oldFields) {
      final newFieldsForState = newFields[state] ?? <dynamic>{};

      for (final field in oldFields.difference(newFieldsForState)) {
        state.removeFieldListener(field, _refresh);
      }
    });

    // Add newly observed field-level dependencies.
    newFields.forEach((state, newFieldsForState) {
      final oldFieldsForState = _fieldDeps[state] ?? <dynamic>{};

      for (final field in newFieldsForState.difference(oldFieldsForState)) {
        state.addFieldListener(field, _refresh);
      }
    });

    _fieldDeps
      ..clear()
      ..addAll(newFields);
  }

  // =========================
  // Reactive trigger
  // =========================

  /// Recomputes the value when dependencies change.
  void _refresh([dynamic _]) {
    if (isDisposed) return;

    _updateValueAndDeps();
  }

  /// Does not allow manually changing the computed value.
  @override
  set value(T newValue) {
    RxDebug.log(
      'Warning: RxComputed is read-only. '
      'Update its dependencies instead.',
    );
  }

  // =========================
  // Cleanup
  // =========================

  /// Disposes all dependency listeners.
  @override
  void dispose() {
    if (isDisposed) return;

    for (final dependency in _deps) {
      dependency.removeListener(_refresh);
    }

    _fieldDeps.forEach((state, fields) {
      for (final field in fields) {
        state.removeFieldListener(field, _refresh);
      }
    });

    _deps.clear();
    _fieldDeps.clear();

    super.dispose();
  }
}

// ========================
// Reactive computed value helpers
// ========================

/// Shorthand extension for accessing the current value
/// of an [RxComputed].
extension RxComputedExtensions<T> on RxComputed<T> {
  /// Returns the current computed value.
  T get v => value;

  /// Returns the current computed value.
  T get current => value;
}

/// Creates a computed boolean value.
RxComputed<bool> rxBool(bool Function() fn) => computed(fn);

/// Creates a computed integer value.
RxComputed<int> rxInt(int Function() fn) => computed(fn);

/// Creates a computed string value.
RxComputed<String> rxString(String Function() fn) => computed(fn);

/// Creates a computed double value.
RxComputed<double> rxDouble(double Function() fn) => computed(fn);
