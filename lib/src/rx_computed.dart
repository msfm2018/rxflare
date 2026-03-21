import 'rx_state.dart';
import 'rx_track.dart';
import 'rx_debug.dart';

/// 全局辅助函数
RxComputed<T> computed<T>(T Function() fn) => RxComputed<T>(fn);

class RxComputed<T> extends RxState<T> {
  final T Function() compute;

  RxComputed(this.compute) : super(compute()) {
    _internalInit();
  }

  void _internalInit() {
    final deps = <RxState>{};

    // 1. 开启追踪：记录计算函数里访问了哪些 .value
    RxTrack.startTracking(deps);
    final initialValue = compute(); 
    RxTrack.stopTracking();

    // 2. 初始化当前值
    internalUpdate(initialValue);

    // 3. 建立联动：只要依赖项变了，就重算
    for (var s in deps) {
      s.addInternalListener((_) {
        final newValue = compute();
        // 如果算出的新值和旧值不同，才触发下游刷新
        internalUpdate(newValue); 
      });
    }
    
    RxDebug.log("🧬 RxComputed(id: $id) 已自动绑定 ${deps.length} 个依赖源");
  }

  @override
  set value(T newValue) => RxDebug.log("⚠️ 警告: 计算属性不支持手动修改，请修改其原始依赖项。");
}