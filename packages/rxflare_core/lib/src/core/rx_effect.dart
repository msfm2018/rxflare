import 'dart:async';

import 'base_.dart';
import 'rx_stack.dart';
import 'rx_state.dart';
import '../utils/rx_debug.dart';

/// Runs a reactive side-effect that automatically re-executes when its
/// dependencies change.
///
/// Returns a dispose function. Call it to stop the effect.
///
/// Example:
/// ```dart
/// final count = 0.obs;
/// final stop = effect(() {
///   print('count is ${count.value}');
/// });
/// count.value = 1; // prints again
/// stop(); // unsubscribe
/// ```
///
/// Unlike [computed], effects do not produce a readable reactive value; they
/// are for side effects (logging, I/O, imperative Flutter calls).
///
/// Multiple dependency notifications in the same event loop turn (e.g. after
/// [batch]) are coalesced into a single re-run via [scheduleMicrotask].
void Function() effect(void Function() fn, {String? name}) {
  return _RxEffect(fn, name: name).dispose;
}

class _RxEffect implements Disposable {
  final void Function() fn;
  final String? name;
  final Set<RxState> _deps = {};
  final Map<RxState, Set<dynamic>> _fieldDeps = {};
  bool _disposed = false;
  bool _running = false;
  bool _scheduled = false;

  _RxEffect(this.fn, {this.name}) {
    _run();
  }

  void _run() {
    if (_disposed || _running) return;
    _running = true;
    final ctx = RxContext();
    try {
      RxStack.push(ctx);
      fn();
      _updateDeps(ctx);
    } finally {
      RxStack.pop();
      _running = false;
    }
  }

  /// Coalesce synchronous multi-dep notifications (typical after [batch]).
  void _refresh([dynamic _]) {
    if (_disposed) return;
    if (_scheduled) return;
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      if (!_disposed) _run();
    });
  }

  void _updateDeps(RxContext ctx) {
    final newStates = ctx.states;
    final newFields = ctx.fields;

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

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
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
    RxDebug.log('RxEffect(${name ?? hashCode}) disposed');
  }
}

/// Watches one or more reactive sources and invokes [callback] when they change.
///
/// [callback] receives the current values. The first call happens immediately
/// unless [immediate] is false.
///
/// Returns a dispose function.
void Function() watch<T>(
  T Function() sources,
  void Function(T value) callback, {
  bool immediate = true,
}) {
  var first = true;

  final stop = effect(() {
    final current = sources();
    if (first) {
      first = false;
      if (immediate) callback(current);
      return;
    }
    callback(current);
  });

  return stop;
}
