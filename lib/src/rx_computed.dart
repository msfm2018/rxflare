import 'rx_state.dart';
import 'rx_track.dart';
import 'rx_debug.dart';

/// 全局辅助函数
RxComputed<T> computed<T>(T Function() fn) => RxComputed<T>(fn);

class RxComputed<T> extends RxState<T> {
  final T Function() compute;

  /// 🔥 记录依赖（state）
  final Set<RxState> _deps = {};

  /// 🔥 记录依赖（field）
  final Map<RxState, Set<dynamic>> _fieldDeps = {};

  RxComputed(this.compute) : super(compute()) {
    _init();
  }

  void _init() {
    _recomputeAndTrack();
    RxDebug.log("🧬 RxComputed(id: $id) 初始化完成");
  }

  /// =========================
  /// 🔥 核心：重算 + 依赖追踪
  /// =========================
  void _recomputeAndTrack() {
    final ctx = RxContext();

    // 1️⃣ 开启追踪
    RxTrack.startTracking(ctx);

    final newValue = compute();

    // 2️⃣ 停止追踪
    RxTrack.stopTracking();

    // 3️⃣ 更新值
    internalUpdate(newValue);

    // 4️⃣ 更新依赖绑定（state + field）
    _updateDeps(ctx);
  }

  /// =========================
  /// 🔥 依赖 diff 更新（核心）
  /// =========================
  void _updateDeps(RxContext ctx) {
    final newStates = ctx.states;
    final newFields = ctx.fields;

    // ========= state =========

    for (final dep in _deps.difference(newStates)) {
      dep.removeListener(_onDependencyChanged);
    }

    for (final dep in newStates.difference(_deps)) {
      dep.addInternalListener(_onDependencyChanged);
    }

    _deps
      ..clear()
      ..addAll(newStates);

    // ========= field =========

    // 移除旧 field
    _fieldDeps.forEach((state, oldFields) {
      final newFs = newFields[state] ?? {};

      for (final field in oldFields.difference(newFs)) {
        state.removeFieldListener(field, _onDependencyChanged);
      }
    });

    // 添加新 field
    newFields.forEach((state, newFs) {
      final oldFs = _fieldDeps[state] ?? {};

      for (final field in newFs.difference(oldFs)) {
        state.addFieldListener(field, _onDependencyChanged);
      }
    });

    _fieldDeps
      ..clear()
      ..addAll(newFields);

    RxDebug.log(
      "🧬 Computed 依赖更新: states=${_deps.length}, fields=${_fieldDeps.length}",
    );
  }

  /// =========================
  /// 🔥 依赖变化触发
  /// =========================
  void _onDependencyChanged([dynamic _]) {
    _recomputeAndTrack();
  }

  @override
  set value(T newValue) {
    RxDebug.log("⚠️ 警告: 计算属性不支持手动修改，请修改其依赖项");
  }

  @override
  void dispose() {
    // 清理 state
    for (final dep in _deps) {
      dep.removeListener(_onDependencyChanged);
    }

    // 清理 field
    _fieldDeps.forEach((state, fields) {
      for (final field in fields) {
        state.removeFieldListener(field, _onDependencyChanged);
      }
    });

    _deps.clear();
    _fieldDeps.clear();

    super.dispose();
  }
}