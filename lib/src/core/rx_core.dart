import '../collections/rx_list.dart';
import '../collections/rx_map.dart';
import '../collections/rx_set.dart';
import '../utils/rx_debug.dart';
import 'rx_state.dart';

import 'package:flutter/material.dart';

/// `RxState` 类型别名
///
/// 提供一些常用别名，方便快速书写：
///
/// 万能扩展：将任何对象转换为 RxState
extension RxAnyExtension<T> on T {
  /// 将当前对象包装成 `RxState<T>`
  RxState<T> get obs => RxState<T>(this);
}

typedef RxValue<T> = RxState<T>;
typedef RxStore<T> = RxState<T>;
typedef RxNotifier<T> = RxState<T>;

// typedef RxList<T> = RxState<List<T>>;
// typedef RxMap<K, V> = RxState<Map<K, V>>;

/// ==============================
/// 基础类型扩展
/// ==============================

/// 将 `int` 转换为 `RxState<int>`
extension RxIntExtension on int {
  /// 将当前 `int` 包装成 `RxState<int>`
  RxState<int> get obs => RxState<int>(this);
}

/// 将 `String` 转换为 `RxState<String>`
extension RxStringExtension on String {
  /// 将当前 `String` 包装成 `RxState<String>`
  RxState<String> get obs => RxState<String>(this);
}

/// 将 `bool` 转换为 `RxState<bool>`
extension RxBoolExtension on bool {
  /// 将当前 `bool` 包装成 `RxState<bool>`
  RxState<bool> get obs => RxState<bool>(this);
}

/// 将 `double` 转换为 `RxState<double>`
extension RxDoubleExtension on double {
  /// 将当前 `double` 包装成 `RxState<double>`
  RxState<double> get obs => RxState<double>(this);
}

// /// 将 `Map` 转换为 `RxState<Map<K, V>>`
// extension RxMapExtension<K, V> on Map<K, V> {
//   /// 将当前 `Map` 包装成 `RxState<Map<K, V>>`
//   RxState<Map<K, V>> get obs => RxState<Map<K, V>>(this);
// }

/// 将 `List` 转换为 `RxState<List<E>>`
extension RxListExtension<E> on List<E> {
  /// 将当前 `List` 包装成 `RxState<List<E>>`
  RxState<List<E>> get obs => RxState<List<E>>(this);
}

/// ==============================
/// List 状态增强扩展
/// ==============================

/// 针对 `RxState<List<T>>` 的增强操作
extension RxListToState<T> on RxState<List<T>> {
  /// 判断是否包含元素
  bool contains(T element) => value.contains(element);

  /// 向列表添加元素，并刷新 UI
  void add(T element) {
    value.add(element);
    refresh(); // 自动触发 UI 更新
  }

  /// 从列表移除元素，并刷新 UI
  void remove(T element) {
    value.remove(element);
    refresh();
  }

  /// 判断是否为空
  bool get isEmpty => value.isEmpty;

  /// 判断是否不为空
  bool get isNotEmpty => value.isNotEmpty;

  /// 获取列表长度
  int get length => value.length;
}

/// ==============================
/// int 类型操作增强
/// ==============================

/// 针对 `RxState<int>` 的增强操作
extension RxIntOps on RxState<int> {
  /// 自增
  void inc() => value++;

  /// 自减
  void dec() => value--;
}

/// ==============================
/// 异步任务扩展
/// ==============================

/// 针对 `RxState<T>` 的异步操作扩展
extension RxAsyncExtension<T> on RxState<T> {
  /// 执行异步任务并自动更新状态
  ///
  /// [task] 异步函数，返回 `T` 类型结果
  /// [loadingState] 可选的 `RxState<bool>`，用于表示加载状态
  /// [retryCount] 重试次数，默认 3
  /// [retryDelay] 每次重试间隔，默认 2 秒
  Future<void> runAsync(
    Future<T> Function() task, {
    RxState<bool>? loadingState,
    int retryCount = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    loadingState?.value = true;

    while (attempts <= retryCount) {
      try {
        attempts++;
        RxDebug.log(" [${name ?? 'Rx'}] 尝试第 $attempts 次任务...");

        final result = await task();

        // 成功则更新值并退出循环
        update(result);
        RxDebug.log(" [${name ?? 'Rx'}] 任务在第 $attempts 次尝试后成功");
        loadingState?.value = false;
        return;
      } catch (e) {
        if (attempts > retryCount) {
          RxDebug.log(" [${name ?? 'Rx'}] 经过 $retryCount 次重试后最终失败: $e");
          loadingState?.value = false;
          rethrow;
        }

        RxDebug.log(" [${name ?? 'Rx'}] 第 $attempts 次尝试失败，正在等待重试...");
        await Future.delayed(retryDelay);
      }
    }
  }
}

/// ==============================
/// Color 扩展
/// ==============================
extension RxColorExtension on Color {
  /// 将 `Color` 转换为 `RxState<Color>`
  RxState<Color> get obs => RxState<Color>(this);
}

/// ==============================
/// 集合类型专用扩展（推荐最终版）
/// ==============================
extension RxFlareCollectionExtensions on Object {
  RxMap<K, V> obsMap<K, V>() => RxMap<K, V>(this as Map<K, V>);

  RxList<T> obsList<T>() => RxList<T>(this as List<T>);

  RxSet<T> obsSet<T>() => RxSet<T>(this as Set<T>);

  // 快捷方式（日常最常用）
  RxMap<String, dynamic> get obsMapD => RxMap<String, dynamic>(this as Map<String, dynamic>);
  RxList<Map<String, dynamic>> get obsListMap => RxList<Map<String, dynamic>>(this as List<Map<String, dynamic>>);
}

