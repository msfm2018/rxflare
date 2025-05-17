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
  const Rx.custom({required this.builder, required this.deps, super.key});

  @override
  State<Rx> createState() => _RxState();
}

class _RxState extends State<Rx> {
  final List<RxState> _dependencies = [];
  late Widget _built;
  int _buildCount = 0;
  Timer? _debounceTimer; // 添加一个 Timer
  @override
  void initState() {
    super.initState();
    _setupReactivity();
  }

  // void _setupReactivity() {
  //   for (final dep in _dependencies) {
  //     dep.removeListener(_onDependencyChanged);
  //   }

  //   _dependencies.clear();
  //   RxTrack.startTracking(_dependencies);
  //   _built = widget.builder();
  //   RxTrack.stopTracking();

  //   for (final dep in _dependencies) {
  //     dep.addListener(_onDependencyChanged);
  //   }

  //   RxDebug.log("📦 当前依赖数量: ${_dependencies.length}");
  // }

  void _setupReactivity() {
    for (final dep in _dependencies) {
      dep.removeListener(_onDependencyChanged);
    }
    _dependencies.clear();

    if (widget.deps != null) {
      _dependencies.addAll(widget.deps!);
      _built = widget.builder(); // 不需要追踪
    } else {
      RxTrack.startTracking(_dependencies);
      _built = widget.builder();
      RxTrack.stopTracking();
    }

    for (final dep in _dependencies) {
      dep.addListener(_onDependencyChanged);
    }

    RxDebug.log("📦 当前依赖数量: ${_dependencies.length}");
  }

  void _onDependencyChanged(dynamic sourceId) {
    if (!mounted) return;
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel(); // 取消之前的 timer
    }

    _debounceTimer = Timer(const Duration(milliseconds: 16), () {
      // 16ms 大约是 60fps 的一帧
      RxDebug.log("🔄 依赖更新: $sourceId，触发第 ${_buildCount + 1} 次重建");

      for (final dep in _dependencies) {
        dep.removeListener(_onDependencyChanged);
      }

      setState(() {
        _setupReactivity();
      });
      _debounceTimer = null; // 重置 timer
    });
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    RxDebug.log("🛠️ 构建第 $_buildCount 次 Rx Widget");

    return _built;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    for (final dep in _dependencies) {
      dep.removeListener(_onDependencyChanged);
    }
    super.dispose();
  }
}
