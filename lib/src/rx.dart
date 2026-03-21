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
  // 使用 Set 替代 List，自动处理重复依赖，提高查找效率
  final Set<RxState> _dependencies = {}; 
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // 初始手动依赖监听
    if (widget.deps != null) {
      _updateListeners(Set.from(widget.deps!));
    }
  }

  /// 差异化更新监听器：只操作变化的部分，优化性能
  void _updateListeners(Set<RxState> newDeps) {
    // 1. 移除不再需要的旧依赖监听
    for (final dep in _dependencies.difference(newDeps)) {
      dep.removeListener(_onDependencyChanged);
    }
    // 2. 添加新增依赖的监听
    for (final dep in newDeps.difference(_dependencies)) {
      dep.addListener(_onDependencyChanged);
    }
    
    // 3. 同步依赖集合
    _dependencies.clear();
    _dependencies.addAll(newDeps);
  }

bool _scheduled = false;

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
      // 模式 A: 手动依赖模式
      return widget.builder();
    } else {
      // 模式 B: 自动追踪模式
      final Set<RxState> discoveredDeps = {};
      
      // 1. 开启追踪
      RxTrack.startTracking(discoveredDeps);
      
      // 2. 执行 builder —— 仅执行这一次！
      // 在这期间，任何被访问的 RxState 都会把自己加入 discoveredDeps
      final result = widget.builder();
      
      // 3. 停止追踪
      RxTrack.stopTracking();
      
      // 4. 根据本次构建发现的依赖更新监听关系
      _updateListeners(discoveredDeps);
      
      RxDebug.log("📦 自动追踪依赖数量: ${discoveredDeps.length}");
      return result;
    }
  }

  @override
  void didUpdateWidget(covariant Rx oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果手动依赖列表变了，需要更新
    if (widget.deps != null && oldWidget.deps != widget.deps) {
      _updateListeners(Set.from(widget.deps!));
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    for (final dep in _dependencies) {
      dep.removeListener(_onDependencyChanged);
    }
    _dependencies.clear();
    super.dispose();
  }
}