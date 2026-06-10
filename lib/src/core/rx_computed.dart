import '../rx_router/rx_router.dart';
import '../utils/rx_debug.dart';
import 'base_.dart';
import 'rx_state.dart';

/// Creates a computed reactive value.
///
/// Example:
/// ```dart
/// final count = RxState<int>(0);
/// final doubled = computed(() => count.value * 2);
///
/// doubled.listen((value) => print(value));
/// count.value = 5; // prints 10
/// ```
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
/// a.value = 3; //  sum = 5
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
  /// The initial value is evaluated immediately.
  RxComputed(this.compute) : super(compute()) {
    _init();
  }

  /// Initializes dependency tracking.
  void _init() {
    _updateValueAndDeps();
    RxDebug.log(" RxComputed(id: $id) 初始化完成");
  }

  // =========================
  // Core recomputation logic
  // =========================

  void _updateValueAndDeps() {
    if (_computing) return;
    _computing = true;

    try {
      final ctx = RxContext();

      // Start dependency collection
      RxStack.push(ctx);

      final newValue = compute();

      // Stop dependency collection
      RxStack.pop();

      // Update dependency graph
      _updateDeps(ctx);

      // Update value
      internalUpdate(newValue);
    } finally {
      _computing = false;
    }
  }

  // =========================
  // Dependency diffing system
  // =========================
  void _updateDeps(RxContext ctx) {
    final newStates = ctx.states;
    final newFields = ctx.fields;

    // Remove stale state dependencies
    for (final dep in _deps.difference(newStates)) {
      dep.removeListener(_refresh);
    }
    for (final dep in newStates.difference(_deps)) {
      dep.addListener(_refresh);
    }
    _deps
      ..clear()
      ..addAll(newStates);

    _fieldDeps.forEach((state, oldFields) {
      final newFs = newFields[state] ?? {};
      for (final field in oldFields.difference(newFs)) {
        state.removeFieldListener(field, _refresh);
      }
    });

    newFields.forEach((state, newFs) {
      final oldFs = _fieldDeps[state] ?? {};

      for (final field in newFs.difference(oldFs)) {
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
    _updateValueAndDeps();
  }

  @override

  /// 不允许手动修改计算属性值
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
    // 清理状态依赖
    for (final dep in _deps) {
      dep.removeListener(_refresh);
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
///
/// Example:
/// ```dart
/// final isDark = rxBool(() => themeMode.value == ThemeMode.dark);
///
/// Container(
///   color: isDark.v ? Colors.black : Colors.white,
/// );
/// ```
extension RxComputedExtensions<T> on RxComputed<T> {
  /// Returns the current computed value.
  ///
  /// Useful when a plain value is required, such as
  /// widget properties that do not automatically
  /// subscribe to reactive updates.
  T get v => value;
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
