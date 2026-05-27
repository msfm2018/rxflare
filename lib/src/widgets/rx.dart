import 'package:flutter/material.dart';
import 'dart:async';

import '../core/base_.dart';
import '../core/rx_state.dart';
import '../rx_router/rx_stack.dart';
import '../utils/rx_debug.dart';

typedef RxWidgetBuilder = Widget Function();

/// [Rx] 是一个响应式包装组件。
///
/// 当其内部 builder 函数依赖的 [RxState] 发生变化时，该组件会自动重新构建。
class Rx extends StatefulWidget {
  /// 构建函数，在其中访问 [RxState.value] 即可自动建立依赖。
  final RxWidgetBuilder builder;

  /// 手动指定的依赖列表（可选）。如果提供，则跳过自动依赖追踪。
  final List<RxState>? deps;

  /// 基础构造函数：开启自动依赖追踪。
  const Rx(this.builder, {super.key}) : deps = null;

  /// 自定义构造函数：手动管理依赖，适用于性能极端优化的特殊场景。
  const Rx.custom({required this.builder, required this.deps, super.key});

  @override
  State<Rx> createState() => _RxState();
}

/// _RxState 是 RxFlare 内部使用的 State 类
///
/// 用于管理 Rx Widget 的依赖追踪和刷新机制：
///
/// - state 级依赖（RxState）
/// - field 级依赖（Map/字段）
/// - 自动/手动模式支持
/// - 防抖刷新，避免重复 setState
class _RxState extends State<Rx> {
  /// 依赖的状态对象集合（state 级依赖）
  final Set<RxState> _dependencies = {};

  /// 字段级依赖集合（RxState -> Set）
  final Map<RxState, Set<dynamic>> _fieldDeps = {};

  /// 防抖定时器（可选）
  Timer? _debounceTimer;

  /// 防抖标记，防止重复刷新
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();

    // 手动依赖模式
    if (widget.deps != null) {
      _updateStateListeners(Set.from(widget.deps!));
    }
  }

  // =========================
  // 🔥 state 依赖更新
  // =========================
  /// 更新 state 级依赖监听器
  void _updateStateListeners(Set<RxState> newDeps) {
    // 移除旧的监听器
    for (final dep in _dependencies.difference(newDeps)) {
      dep.removeListener(refresh);
    }

    // 添加新的
    for (final dep in newDeps.difference(_dependencies)) {
      dep.addListener(refresh);
    }

    _dependencies
      ..clear()
      ..addAll(newDeps);
  }

  // =========================
  // 🔥 field 依赖更新（核心）
  // =========================
  /// 更新 field 级依赖监听器
  void _updateFieldListeners(Map<RxState, Set<dynamic>> newFieldDeps) {
    // 移除旧的 field listener
    _fieldDeps.forEach((state, oldFields) {
      final newFields = newFieldDeps[state] ?? {};

      for (final field in oldFields.difference(newFields)) {
        state.removeFieldListener(field, refresh);
      }
    });

    //  添加新的 field listener
    newFieldDeps.forEach((state, newFields) {
      final oldFields = _fieldDeps[state] ?? {};

      for (final field in newFields.difference(oldFields)) {
        state.addFieldListener(field, refresh);
      }
    });

    //  同步更新
    _fieldDeps
      ..clear()
      ..addAll(newFieldDeps);
  }

  // =========================
  // 🔥 统一更新入口
  // =========================
  /// 更新 state + field 依赖监听器
  void _updateListeners(RxContext ctx) {
    _updateStateListeners(ctx.states);
    _updateFieldListeners(ctx.fields);
  }

  // =========================
  // 响应更新（防抖）
  // =========================

  /// 响应依赖变化触发刷新
  ///
  /// [triggerInfo] 可选，用于日志显示
  void refresh([dynamic triggerInfo]) {
    if (!mounted || _scheduled) return;
    RxDebug.log("🔥 [触发刷新] 来源: ${triggerInfo.toString()} -> 准备执行 setState");
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

    // 1️ 开始追踪
    RxStack.push(ctx);

    // 2️ 执行 builder
    final result = widget.builder();

    // 3️ 停止追踪
    RxStack.pop();

    // 4️ 更新监听（state + field） 等待数据的下一次变化时触发刷新
    _updateListeners(ctx);
    RxDebug.log("📦 依赖统计: states=${ctx.states.length}, fields=${ctx.fields.length}");

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
      dep.removeListener(refresh);
    }

    // 🔥 清理 field listener（必须有）
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
