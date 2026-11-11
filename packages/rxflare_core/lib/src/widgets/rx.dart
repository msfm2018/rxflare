import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'dart:async';

import '../core/base_.dart';
import '../core/rx_state.dart';
import '../core/rx_stack.dart';
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

  void _updateFieldListeners(
    Map<RxState, Set<dynamic>> newFieldDeps,
  ) {
    // RxDebug.log('========== UPDATE FIELD LISTENERS ==========');

    _fieldDeps.forEach((state, oldFields) {
      final newFields = newFieldDeps[state] ?? {};

      for (final field in oldFields.difference(newFields)) {
        RxDebug.log('REMOVE FIELD: $field');
        state.removeFieldListener(field, refresh);
      }
    });

    newFieldDeps.forEach((state, newFields) {
      final oldFields = _fieldDeps[state] ?? {};

      for (final field in newFields.difference(oldFields)) {
        RxDebug.log('ADD FIELD: $field');
        state.addFieldListener(field, refresh);
      }
    });

    _fieldDeps
      ..clear()
      ..addAll(newFieldDeps);

    RxDebug.log('FIELD LISTENER COUNT: $_fieldDeps');
  }

  void _updateListeners(RxContext ctx) {
    _updateStateListeners(ctx.states);
    _updateFieldListeners(ctx.fields);
  }

  /// Triggers a rebuild when dependencies change.
  ///
  /// Uses synchronous [setState] when safe. If a refresh is requested during
  /// the build/layout/paint phase, it is deferred to a post-frame callback.
  /// Prefer wrapping multi-value writes in [batch] so multiple changes
  /// collapse into a single rebuild.

  void refresh([dynamic triggerInfo]) {
    RxDebug.log('RX REFRESH CALLED: $triggerInfo');

    if (!mounted) return;

    final phase = SchedulerBinding.instance.schedulerPhase;

    if (phase == SchedulerPhase.persistentCallbacks) {
      // 正在 build/layout/paint 中，不能直接 setState
      if (_scheduled) return;
      _scheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scheduled = false;
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    RxDebug.log(" Rx Widget rebuilding...");

    if (widget.deps != null) {
      return widget.builder();
    }

    final RxContext ctx = RxContext();

    Widget result;

    RxStack.push(ctx);

    try {
      result = widget.builder();
    } finally {
      RxStack.pop();
    }

    _updateListeners(ctx);

    RxDebug.log(
      "Rx dependencies tracked: "
      "states=${ctx.states.length}, "
      "fields=${ctx.fields.length}",
    );

    return result;
  }

  void _clearFieldListeners() {
    _fieldDeps.forEach((state, fields) {
      for (final field in fields) {
        state.removeFieldListener(field, refresh);
      }
    });

    _fieldDeps.clear();
  }

  @override
  void didUpdateWidget(covariant Rx oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 自动模式切换到手动模式
    if (widget.deps != null && oldWidget.deps == null) {
      _clearFieldListeners();

      _updateStateListeners(Set.from(widget.deps!));
      return;
    }

    // 手动模式切换到自动模式
    if (widget.deps == null && oldWidget.deps != null) {
      _updateStateListeners({});
      return;
    }

    // 手动依赖发生变化
    if (widget.deps != null && oldWidget.deps != widget.deps) {
      _updateStateListeners(Set.from(widget.deps!));
    }
  }

  // @override
  // void didUpdateWidget(covariant Rx oldWidget) {
  //   super.didUpdateWidget(oldWidget);

  //   if (widget.deps != null && oldWidget.deps != widget.deps) {
  //     _updateStateListeners(Set.from(widget.deps!));
  //   }
  // }

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

/// [Obx] 是 [Rx] 的响应式包装组件。
///
/// 会自动监听在 [builder] 中访问过的所有 [RxState] / `.obs` 变量，
/// 当这些变量发生改变时自动触发局部刷新。
class Obx extends Rx {
  /// 创建一个具有 **自动依赖追踪** 的响应式组件。
  const Obx(super.builder, {super.key});

  /// 创建一个 **手动指定依赖** 的响应式组件（高级用法）。
  const Obx.custom({required super.builder, required super.deps, super.key})
      : super.custom();
}
