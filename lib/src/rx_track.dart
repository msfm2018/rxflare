import 'rx_state.dart';
import 'rx_debug.dart';

class RxContext {
  final Set<RxState> states = {};
  final Map<RxState, Set<dynamic>> fields = {};
}

class RxTrack {
  // 🔥 当前依赖上下文
  static RxContext? _current;

  // ✅ 开始追踪
  static void startTracking(RxContext ctx) {
    _current = ctx;
    RxDebug.log("🔍 开始追踪依赖");
  }

  // ✅ 结束追踪
  static void stopTracking() {
    RxDebug.log("✅ 停止追踪依赖");
    _current = null;
  }

  // ✅ state 级依赖
  static void register(RxState state) {
    if (_current != null) {
      RxDebug.log("➕ 注册 state 依赖: ${state.name ?? state.id}");
      _current!.states.add(state);
    }
  }

  static void registerField(RxState state, dynamic field) {
    if (_current != null) {
      RxDebug.log("➕ 注册 field 依赖: ${state.name ?? state.id}[$field]");
      _current!.fields.putIfAbsent(state, () => <dynamic>{}).add(field);
    }
  }
}
