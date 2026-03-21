// import 'rx_state.dart';

// extension RxExtension<T> on T {
//   // 基础类型的 .obs (int, String, bool)
//   RxState<T> get obs => RxState<T>(this);
// }

// extension RxListExtension<E> on List<E> {
//   // 专门给 List 用的 .obs，保持内部元素类型正确
//   RxState<List<E>> get obs => RxState<List<E>>(this);
// }

import 'rx_debug.dart';
import 'rx_state.dart';
extension RxIntExtension on int {
  /// 将 int 转换为 RxState<int>
  RxState<int> get obs => RxState<int>(this);
}

extension RxStringExtension on String {
  /// 将 String 转换为 RxState<String>
  RxState<String> get obs => RxState<String>(this);
}

extension RxBoolExtension on bool {
  /// 将 bool 转换为 RxState<bool>
  RxState<bool> get obs => RxState<bool>(this);
}

extension RxDoubleExtension on double {
  /// 将 double 转换为 RxState<double>
  RxState<double> get obs => RxState<double>(this);
}

// 甚至可以针对 Map 和 List 做扩展
extension RxMapExtension<K, V> on Map<K, V> {
  RxState<Map<K, V>> get obs => RxState<Map<K, V>>(this);
}

extension RxListExtension<E> on List<E> {
  RxState<List<E>> get obs => RxState<List<E>>(this);
}

// ===== 操作增强 =====
extension RxIntOps on RxState<int> {
  void inc() => value++;
  void dec() => value--;
}



extension RxAsyncExtension<T> on RxState<T> {
  /// 自动处理异步逻辑，支持重试机制
  Future<void> runAsync(
    Future<T> Function() task, {
    RxState<bool>? loadingState,
    int retryCount = 3, // 默认重试 3 次
    Duration retryDelay = const Duration(seconds: 2), // 每次重试间隔 2 秒
  }) async {
    int attempts = 0;
    loadingState?.value = true;

    while (attempts <= retryCount) {
      try {
        attempts++;
        RxDebug.log("⏳ [${name ?? 'Rx'}] 尝试第 $attempts 次任务...");
        
        final result = await task();
        
        // 成功则更新值并退出循环
        update(result);
        RxDebug.log("✅ [${name ?? 'Rx'}] 任务在第 $attempts 次尝试后成功");
        loadingState?.value = false;
        return; 
      } catch (e) {
        if (attempts > retryCount) {
          // 尝试次数用尽
          RxDebug.log("❌ [${name ?? 'Rx'}] 经过 $retryCount 次重试后最终失败: $e");
          loadingState?.value = false;
          rethrow; // 抛出错误供外部处理
        }
        
        RxDebug.log("⚠️ [${name ?? 'Rx'}] 第 $attempts 次尝试失败，正在等待重试...");
        await Future.delayed(retryDelay);
      }
    }
  }
}


