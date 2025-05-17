import 'rx_core.dart';
import 'rx_debug.dart';


//追踪花费时间
class RxTrack {
  static List<RxValue>? _currentDependencies;

  static void startTracking(List<RxValue> targetList) {
    _currentDependencies = targetList;
    RxDebug.log("🔍 开始追踪依赖");
  }

  static void stopTracking() {
    RxDebug.log("✅ 停止追踪依赖");
    _currentDependencies = null;
  }

  static void register(RxValue state) {
    if (_currentDependencies != null) {
      RxDebug.log("➕ 注册依赖: ${state.runtimeType}");
      _currentDependencies!.add(state);
    }
  }
}
