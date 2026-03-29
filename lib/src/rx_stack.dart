import 'rx_state.dart';
import 'rx_debug.dart';

class RxContext {
  final Set<RxState> states = {};
  final Map<RxState, Set<dynamic>> fields = {};
}

class RxStack {
  // 🔥 改为栈结构，存储嵌套的上下文
  static final List<RxContext> _stack = [];

  // 获取当前最顶层的上下文（即当前正在构建的那个 Rx Widget）
  static RxContext? get _current => _stack.isNotEmpty ? _stack.last : null;

  static void push(RxContext ctx) {
    _stack.add(ctx);
  }

  static void pop() {
    if (_stack.isNotEmpty) {
      _stack.removeLast();
    }
  }

  // ✅ 注册 state 级依赖
  static void register(RxState state) {
    final ctx = _current;
    if (ctx != null) {
      // 避免重复打印，只有真正添加成功才 Log
      if (ctx.states.add(state)) {
        RxDebug.log("➕ 绑定 State: ${state.name ?? state.id}");
      }
    }
  }

  // ✅ 注册 field 级依赖
  static void registerField(RxState state, dynamic field) {
    final ctx = _current;
    if (ctx != null) {
      final fields = ctx.fields.putIfAbsent(state, () => <dynamic>{});
      if (fields.add(field)) {
        RxDebug.log("➕ 绑定 Field: ${state.name ?? state.id}[$field]");
      }
    }
  }
}
