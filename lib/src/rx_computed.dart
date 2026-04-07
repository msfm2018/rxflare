import 'rx_state.dart';
import 'rx_stack.dart';
import 'rx_debug.dart';

/// 创建一个计算属性的快捷方法。
///
/// [fn] 是计算函数，会返回计算值。
/// 使用示例：
///
/// ```dart
/// final count = RxState<int>(0);
/// final doubled = computed(() => count.value * 2);
///
/// doubled.listen((val) => print('doubled = $val'));
///
/// count.value = 5; // 输出: doubled = 10
/// ```
RxComputed<T> computed<T>(T Function() fn) => RxComputed<T>(fn);

/// 响应式计算属性类。
///
/// `RxComputed` 会根据依赖的 [RxState] 自动计算值，并在依赖变化时刷新。
/// 
/// 特性：
/// - 自动追踪依赖的状态对象和字段。
/// - 当依赖变化时自动更新值。
/// - 不允许手动修改值，只能修改依赖的状态。
///
/// 示例：
///
/// ```dart
/// final a = RxState<int>(1);
/// final b = RxState<int>(2);
/// final sum = RxComputed<int>(() => a.value + b.value);
///
/// sum.listen((val) => print('sum = $val'));
/// a.value = 3; // 输出: sum = 5
/// ```
class RxComputed<T> extends RxState<T> {
  /// 计算函数
  final T Function() compute;

  /// 🔥 记录依赖的状态对象
  final Set<RxState> _deps = {};

  /// 🔥 记录依赖的字段
  final Map<RxState, Set<dynamic>> _fieldDeps = {};

  /// 构造函数。
  ///
  /// [compute] 是计算函数，会在初始化时立即计算一次。
  RxComputed(this.compute) : super(compute()) {
    _init();
  }

  /// 初始化计算属性。
  ///
  /// 内部会更新值并记录依赖。
  void _init() {
    _updateValueAndDeps();
    RxDebug.log("🧬 RxComputed(id: $id) 初始化完成");
  }

  // =========================
  // 🔥 核心方法：重算 + 依赖追踪
  // =========================
  void _updateValueAndDeps() {
    final ctx = RxContext();

    // 1️⃣ 开启依赖追踪
    RxStack.push(ctx);

    final newValue = compute();

    // 2️⃣ 停止追踪
    RxStack.pop();

    // 3️⃣ 更新值
    internalUpdate(newValue);

    // 4️⃣ 更新依赖绑定（状态 + 字段）
    _updateDeps(ctx);
  }

  // =========================
  // 🔥 依赖 diff 更新（核心）
  // =========================
  void _updateDeps(RxContext ctx) {
    final newStates = ctx.states;
    final newFields = ctx.fields;

    // ========= 状态依赖 =========
    for (final dep in _deps.difference(newStates)) {
      dep.removeListener(_refresh);
    }
    for (final dep in newStates.difference(_deps)) {
      dep.addInternalListener(_refresh);
    }
    _deps
      ..clear()
      ..addAll(newStates);

    // ========= 字段依赖 =========
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

    RxDebug.log("🧬 Computed 依赖更新: states=${_deps.length}, fields=${_fieldDeps.length}");
  }

  // =========================
  // 🔥 依赖变化触发刷新
  // =========================

  /// 当依赖的状态或字段变化时刷新计算值
  void _refresh([dynamic _]) {
    _updateValueAndDeps();
  }

  @override
  /// 不允许手动修改计算属性值
  set value(T newValue) {
    RxDebug.log("⚠️ 警告: 计算属性不支持手动修改，请修改其依赖项");
  }

  @override
  /// 清理计算属性的所有依赖监听
  void dispose() {
    // 清理状态依赖
    for (final dep in _deps) {
      dep.removeListener(_refresh);
    }

    // 清理字段依赖
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