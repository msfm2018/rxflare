import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:rxflare/rxflare.dart';
import 'rx_state.dart'; // ← 确保导入 RxState
/// RxObjMgr 是一个全局依赖注入管理器
///
/// 提供单例注入、懒加载和按类型或名称查找实例的功能。
/// 可以用于全局管理对象、服务或控制器。
///
/// 示例：
/// ```dart
/// // 注册单例
/// final controller = MyController();
/// RxObjMgr.put(controller);
///
/// // 懒加载
/// RxObjMgr.lazyPut(() => MyController());
///
/// // 查找实例
/// final c = RxObjMgr.find<MyController>();
///
/// // 删除实例
/// RxObjMgr.delete<MyController>();
/// ```

/// RxObjMgr 是一个全局依赖注入管理器
class RxObjMgr {
  /// 单例对象池
  static final Map<Object, dynamic> _singletonMap = {};

  /// 工厂方法池（懒加载）
  static final Map<Object, dynamic Function()> _factoryMap = {};

  /// 调试模式
  static bool debugEnabled = true; // kDebugMode;

  /// 活跃的 RxState
  static final Map<String, dynamic> _rxStates = {};

  /// Computed 属性集合
  static final Map<String, dynamic> _computed = {};

  /// 已销毁的 RxState（用于 DevTools 显示历史）
  static final Map<String, dynamic> _disposedRxStates = {};
  static final Map<String, DateTime> _disposeTimestamps = {};

  /// EventBus 调试事件流
  static final StreamController<dynamic> _eventController = StreamController<dynamic>.broadcast();

  static Stream<dynamic> get debugEventStream => _eventController.stream;

  // ==================== DevTools 初始化 ====================
  static void initDevTools() {
    if (!kDebugMode) return;

     bool isRegistered = false;
    if (!isRegistered) {
      try {
        developer.registerExtension('ext.rxflare.getSnapshot', (method, parameters) async {
          try {
            final data = getDebugSnapshot();
            return developer.ServiceExtensionResponse.result(jsonEncode({
              'success': true,
              'data': data,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            }));
          } catch (e, st) {
            // debugPrint('[RxFlare] getSnapshot Error: $e $st');
            return developer.ServiceExtensionResponse.error(0, 'Snapshot failed: $e $st');
          }
        });

        isRegistered = true;
        _log('DEBUG', 'DevTools Service Extension registered successfully.');
      } catch (e) {
        // debugPrint('[RxFlare] 注册 DevTools 失败: $e');
      }
    }
  }

  /// 获取 DevTools 快照（核心方法）
  static Map<String, dynamic> getDebugSnapshot() {
    final rxStatesData = <String, dynamic>{};

    // 1. 活跃的 RxState
    _rxStates.forEach((key, obj) {
      try {
        if (obj is RxState) {
          rxStatesData[key] = {
            'status': 'alive',
            'value': obj.value.toString(),
            'type': obj.runtimeType.toString(),
            'name': obj.name ?? '无名称',
          };
        } else {
          rxStatesData[key] = obj.toString();
        }
      } catch (e) {
        rxStatesData[key] = {'status': 'alive', 'value': '<读取失败>'};
      }
    });

    // 2. 已销毁的 RxState
    _disposedRxStates.forEach((key, obj) {
      rxStatesData[key] = {
        'status': 'disposed',
        'value': '<已销毁>',
        'disposedAt': _disposeTimestamps[key]?.toString() ?? '未知时间',
        'type': obj.runtimeType.toString(),
      };
    });

    return {
      'singletons': _singletonMap.map((k, v) => MapEntry(k.toString(), v.runtimeType.toString())),
      'rxStates': rxStatesData,
      'computed': _computed.map((k, v) => MapEntry(k, v.toString())),
      'factoryCount': _factoryMap.length,
      'aliveCount': _rxStates.length,
      'disposedCount': _disposedRxStates.length,
    };
  }

  // ==================== 注册 / 查找 / 删除 ====================

  static T put<T>(T dependency, {String? name}) {
    final key = name ?? T;
    _singletonMap[key] = dependency;
    if (debugEnabled) _log('PUT', 'Registered $T${name != null ? " ($name)" : ""}');
    return dependency;
  }

  static void lazyPut<T>(T Function() builder, {String? name}) {
    final key = name ?? T;
    _factoryMap[key] = builder;
    if (debugEnabled) _log('LAZY_PUT', 'Lazy registered $T');
  }

  static T find<T>({String? name}) {
    final key = name ?? T;
    if (_singletonMap.containsKey(key)) {
      return _singletonMap[key] as T;
    }
    if (_factoryMap.containsKey(key)) {
      final dep = _factoryMap[key]!();
      _singletonMap[key] = dep;
      _factoryMap.remove(key);
      return dep as T;
    }
    throw " [注入错误] 未找到 '$key'";
  }

  static T? findOrNull<T>({String? name}) {
    final key = name ?? T;
    return _singletonMap[key] as T?;
  }

  static void delete<T>({String? name}) {
    final key = name ?? T;
    _singletonMap.remove(key);
    _factoryMap.remove(key);
    if (debugEnabled) _log('DELETE', 'Removed $T');
  }

  // ==================== RxState 注册与销毁 ====================

  static void registerRxState<T>(T state, {String? debugName}) {
    if (!debugEnabled) return;
    final name = debugName ?? '${T}_${state.hashCode}';
    _rxStates[name] = state;
    _log('REGISTER_RX', name);
  }

  static void registerComputed<T>(T computed, {String? debugName}) {
    if (!debugEnabled) return;
    final name = debugName ?? 'Computed_${T}_${computed.hashCode}';
    _computed[name] = computed;
    _log('REGISTER_COMPUTED', name);
  }

  /// 移除并记录销毁状态
  static void unregisterRx(dynamic rxObject) {
    if (!debugEnabled) return;

    String? removedKey;

    _rxStates.removeWhere((key, value) {
      if (value == rxObject) {
        removedKey = key;
        return true;
      }
      return false;
    });

    _computed.removeWhere((key, value) => value == rxObject);

    if (removedKey != null) {
      _disposedRxStates[removedKey!] = rxObject;
      _disposeTimestamps[removedKey!] = DateTime.now();
      _log('DISPOSED', '$removedKey 已销毁');
    }
  }

  static void clearDebugData() {
    _rxStates.clear();
    _computed.clear();
    // _disposedRxStates.clear(); // 保留历史记录
    _log('DEBUG', 'All active debug data cleared');
  }

  static void _log(String type, String message) {
    // debugPrint('[RxFlare] $type → $message');
  }
}

/// RxParent 用于将依赖注入 Widget 树
///
/// 在 Widget 生命周期内自动注册和释放对象。
/// 常用于全局或页面级控制器注入。
///
/// 示例：
/// ```dart
/// RxParent<MyController>(
///   dependency: MyController(),
///   child: MyHomePage(),
/// );
/// ```
class RxParent<T> extends StatefulWidget {
  /// 要注入的依赖对象
  final T dependency;

  /// 可选名称，用于区分同类型对象
  final String? name;

  /// 子 Widget
  final Widget child;

  /// 构造函数
  const RxParent({super.key, required this.dependency, this.name, required this.child});

  @override
  State<RxParent<T>> createState() => _RxParentState<T>();
}

class _RxParentState<T> extends State<RxParent<T>> {
  @override
  void initState() {
    super.initState();
    // 注册依赖
    RxObjMgr.put<T>(widget.dependency, name: widget.name);
  }

  // @override
  // void dispose() {
  //   // 尝试调用 dispose 方法
  //   final dynamic instance = RxObjMgr.find<T>(name: widget.name);
  //   instance?.dispose?.call();

  //   // 删除依赖
  //   RxObjMgr.delete<T>(name: widget.name);
  //   super.dispose();
  // }

  @override
  void dispose() {
    final dynamic instance = RxObjMgr.findOrNull<T>(name: widget.name);

    instance?.dispose?.call();
    // print("---------------->${widget.name}");
    RxObjMgr.delete<T>(name: widget.name);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
