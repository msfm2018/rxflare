import 'package:flutter/material.dart';
import 'dart:async';
import 'rx_track.dart';
import 'rx_debug.dart';
import 'rx_state.dart';

typedef RxWidgetBuilder = Widget Function();

class Rx extends StatefulWidget {
  final RxWidgetBuilder builder;
  final List<RxState>? deps;

  const Rx(this.builder, {super.key}) : deps = null;

  const Rx.custom({
    required this.builder,
    required this.deps,
    super.key,
  });

  @override
  State<Rx> createState() => _RxState();
}

class _RxState extends State<Rx> {
  /// state 级依赖
  final Set<RxState> _dependencies = {};

  /// 🔥 field 级依赖（新增）
  final Map<RxState, Set<dynamic>> _fieldDeps = {};

  Timer? _debounceTimer;

  bool _scheduled = false;

  @override
  void initState() {
    super.initState();

    // 手动依赖模式
    if (widget.deps != null) {
      _updateStateListeners(Set.from(widget.deps!));
    }
  }

  /// =========================
  /// 🔥 state 依赖更新
  /// =========================
  void _updateStateListeners(Set<RxState> newDeps) {
    // 移除旧的
    for (final dep in _dependencies.difference(newDeps)) {
      dep.removeListener(_onDependencyChanged);
    }

    // 添加新的
    for (final dep in newDeps.difference(_dependencies)) {
      dep.addListener(_onDependencyChanged);
    }

    _dependencies
      ..clear()
      ..addAll(newDeps);
  }

  /// =========================
  /// 🔥 field 依赖更新（核心）
  /// =========================
  void _updateFieldListeners(Map<RxState, Set<dynamic>> newFieldDeps) {
    // 1️⃣ 移除旧的 field listener
    _fieldDeps.forEach((state, oldFields) {
      final newFields = newFieldDeps[state] ?? {};

      for (final field in oldFields.difference(newFields)) {
        state.removeFieldListener(field, _onDependencyChanged);
      }
    });

    // 2️⃣ 添加新的 field listener
    newFieldDeps.forEach((state, newFields) {
      final oldFields = _fieldDeps[state] ?? {};

      for (final field in newFields.difference(oldFields)) {
        state.addFieldListener(field, _onDependencyChanged);
      }
    });

    // 3️⃣ 同步
    _fieldDeps
      ..clear()
      ..addAll(newFieldDeps);
  }

  /// =========================
  /// 🔥 统一更新入口
  /// =========================
  void _updateListeners(RxContext ctx) {
    _updateStateListeners(ctx.states);
    _updateFieldListeners(ctx.fields);
  }

  /// =========================
  /// 🔥 响应更新（防抖）
  /// =========================
  void _onDependencyChanged([dynamic _]) {
    if (!mounted || _scheduled) return;

    _scheduled = true;

    scheduleMicrotask(() {
      if (mounted) setState(() {});
      _scheduled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    RxDebug.log("🛠️ Rx Widget 构建中...");

    if (widget.deps != null) {
      // 手动依赖模式
      return widget.builder();
    }

    // 🔥 自动依赖模式（升级版）
    final RxContext ctx = RxContext();

    // 1️⃣ 开始追踪
    RxTrack.startTracking(ctx);

    // 2️⃣ 执行 builder
    final result = widget.builder();

    // 3️⃣ 停止追踪
    RxTrack.stopTracking();

    // 4️⃣ 更新监听（state + field）
    _updateListeners(ctx);

    RxDebug.log(
      "📦 依赖统计: states=${ctx.states.length}, fields=${ctx.fields.length}",
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

    // 清理 state listener
    for (final dep in _dependencies) {
      dep.removeListener(_onDependencyChanged);
    }

    // 🔥 清理 field listener（必须有）
    _fieldDeps.forEach((state, fields) {
      for (final field in fields) {
        state.removeFieldListener(field, _onDependencyChanged);
      }
    });

    _dependencies.clear();
    _fieldDeps.clear();

    super.dispose();
  }
}