import 'rx_state.dart';
import 'rx_debug.dart';


class RxTrack {
  static Set<RxState>? _current;

  static void startTracking(Set<RxState> deps) {
    _current = deps;
    RxDebug.log("🔍 开始追踪依赖");
  }

  static void stopTracking() {
    RxDebug.log("✅ 停止追踪依赖");
    _current = null;
  }

  static void register(RxState state) {
    if (_current != null) {
      RxDebug.log("➕ 注册依赖: ${state.name ?? state.id}");
      _current!.add(state);
    }
  }
}
