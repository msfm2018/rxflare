import 'package:flutter/material.dart';
import 'dart:async';

import '../core/base_.dart';
import '../core/rx_state.dart';
import '../rx_router/rx_stack.dart';
import '../utils/rx_debug.dart';

/// Signature for the builder function used by [Rx].
typedef RxWidgetBuilder = Widget Function();

/// The core reactive widget of **RxFlare**.
///
/// [Rx] automatically tracks dependencies on [RxState] objects during the
/// `builder` execution and rebuilds only when those dependencies change.
///
/// It supports two modes:
/// - **Automatic dependency tracking** (default, recommended)
/// - **Manual dependency specification** (`Rx.custom`)
///
/// **Example (Automatic):**
/// ```dart
/// final count = 0.obs;
///
/// Rx(() => Text('Count: ${count.value}'));
/// ```
class Rx extends StatefulWidget {
  /// The builder function. Any accessed [RxState] inside will be automatically tracked.
  final RxWidgetBuilder builder;

  /// Manually specified dependencies (for advanced performance optimization).
  /// When provided, automatic tracking is disabled.
  final List<RxState>? deps;

  /// Creates an [Rx] widget with **automatic dependency tracking**.
  const Rx(this.builder, {super.key}) : deps = null;

  /// Creates an [Rx] widget with **manual dependencies** (advanced use).
  const Rx.custom({required this.builder, required this.deps, super.key});

  @override
  State<Rx> createState() => _RxState();
}

/// Internal state class for [Rx].
///
/// Manages:
/// - Automatic & manual dependency tracking
/// - State-level and field-level listeners
/// - Debounced / microtask-based rebuilding
/// - Proper cleanup on dispose
class _RxState extends State<Rx> {
  /// All state-level dependencies being listened to.
  final Set<RxState> _dependencies = {};

  /// Field-level dependencies (RxState → Set of keys/indices).
  final Map<RxState, Set<dynamic>> _fieldDeps = {};

  /// Debounce timer (currently unused but kept for future extensions).
  Timer? _debounceTimer;

  /// Prevents multiple simultaneous refresh schedules.
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();

    if (widget.deps != null) {
      _updateStateListeners(Set.from(widget.deps!));
    }
  }

  // ======================
  // State-level Listeners
  // ======================
  void _updateStateListeners(Set<RxState> newDeps) {
    // Remove old listeners
    for (final dep in _dependencies.difference(newDeps)) {
      dep.removeListener(refresh);
    }

    // Add new listeners
    for (final dep in newDeps.difference(_dependencies)) {
      dep.addListener(refresh);
    }

    _dependencies
      ..clear()
      ..addAll(newDeps);
  }

  // ======================
  // Field-level Listeners (Core Feature)
  // ======================
  void _updateFieldListeners(Map<RxState, Set<dynamic>> newFieldDeps) {
    // Remove old field listeners
    _fieldDeps.forEach((state, oldFields) {
      final newFields = newFieldDeps[state] ?? {};

      for (final field in oldFields.difference(newFields)) {
        state.removeFieldListener(field, refresh);
      }
    });

    // Add new field listeners
    newFieldDeps.forEach((state, newFields) {
      final oldFields = _fieldDeps[state] ?? {};

      for (final field in newFields.difference(oldFields)) {
        state.addFieldListener(field, refresh);
      }
    });

    _fieldDeps
      ..clear()
      ..addAll(newFieldDeps);
  }

  void _updateListeners(RxContext ctx) {
    _updateStateListeners(ctx.states);
    _updateFieldListeners(ctx.fields);
  }

  /// Triggers a rebuild when dependencies change.
  ///
  /// Uses `scheduleMicrotask` to batch updates efficiently.
  void refresh([dynamic triggerInfo]) {
    if (!mounted || _scheduled) return;
    RxDebug.log("🔥 [Rx Refresh] Triggered by: $triggerInfo");
    _scheduled = true;

    scheduleMicrotask(() {
      if (mounted) setState(() {});
      _scheduled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    RxDebug.log("🛠️ Rx Widget rebuilding...");

    if (widget.deps != null) {
      // Manual dependency mode
      return widget.builder();
    }

    // === Automatic Dependency Tracking ===
    final RxContext ctx = RxContext();

    // Start tracking
    RxStack.push(ctx);

    final result = widget.builder();

    // Stop tracking
    RxStack.pop();

    _updateListeners(ctx);
    RxDebug.log(
      "📦 Rx dependencies tracked: states=${ctx.states.length}, fields=${ctx.fields.length}",
    );

    return result;
  }

  @override
  void didUpdateWidget(covariant Rx oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.deps != null && oldWidget.deps != widget.deps) {
      _updateStateListeners(Set.from(widget.deps!));
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();

    // Clean up state listeners
    for (final dep in _dependencies) {
      dep.removeListener(refresh);
    }

    // Clean up field listeners
    _fieldDeps.forEach((state, fields) {
      for (final field in fields) {
        state.removeFieldListener(field, refresh);
      }
    });

    _dependencies.clear();
    _fieldDeps.clear();

    super.dispose();
  }
}
