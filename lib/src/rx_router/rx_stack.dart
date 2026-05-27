import '../core/base_.dart';
import '../core/rx_state.dart';
import '../utils/rx_debug.dart';



/// RxStack 是 RxFlare 的依赖栈
///
/// 用于在响应式计算或 Widget 构建时追踪状态和字段依赖。
/// 通过 push/pop 管理嵌套上下文，并提供注册方法。
class RxStack {
  /// 内部栈，用于存储嵌套上下文
  static final List<RxContext> _stack = [];

  /// 获取当前顶层上下文
  static RxContext? get current => _stack.isNotEmpty ? _stack.last : null;

  /// 将上下文推入栈顶
  static void push(RxContext ctx) {
    _stack.add(ctx);
  }

  /// 弹出栈顶上下文
  static void pop() {
    if (_stack.isNotEmpty) {
      _stack.removeLast();
    }
  }

  /// 注册 state 级依赖
  ///
  /// [state] 要注册的 RxState
  /// 会记录到当前上下文的 states 集合中
  static void register(RxState state) {
    final ctx = current;
    if (ctx != null) {
      // 仅在添加成功时打印日志
      if (ctx.states.add(state)) {
        RxDebug.log(" 绑定 State: ${state.name ?? state.id}");
      }
    }
  }

  /// 注册字段级依赖
  ///
  /// [state] 所属 RxState
  /// [field] 字段标识
  /// 会记录到当前上下文的 fields 集合中
  static void registerField(RxState state, dynamic field) {
    final ctx = current;
    if (ctx != null) {
      final fields = ctx.fields.putIfAbsent(state, () => <dynamic>{});
      if (fields.add(field)) {
        RxDebug.log(" 绑定 Field: ${state.name ?? state.id}[$field]");
      }
    }
  }
}
