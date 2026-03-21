import 'dart:async';
import 'rx_debug.dart';

enum EventPriority { high, normal, low }

// 保持泛型定义，方便外部调用时有类型推断
typedef EventCallback<T> = Future<void> Function(int eventID, String uuid, T data);

class EventToken {
  final String id = DateTime.now().microsecondsSinceEpoch.toString();
}

/// 内部包装类：解决类型逆变问题
class _EventWrapper {
  // 统一存储为 dynamic，供内部调度使用
  final Future<void> Function(int eventID, String uuid, dynamic data) wrapperCallback;
  // 存储原始引用，用于 off() 时的比对
  final dynamic originalCallback;
  final EventToken? token;

  _EventWrapper({
    required this.wrapperCallback, 
    required this.originalCallback, 
    this.token
  });
}

class _EventTask {
  final String module;
  final int eventID;
  final dynamic data;
  final String uuid;
  final EventPriority priority;
  final bool parallel;

  _EventTask({
    required this.module, 
    required this.eventID, 
    required this.data, 
    required this.uuid, 
    required this.priority, 
    required this.parallel
  });
}

class RxEventBus {
  /// 注册表：List 存储的是统一的 _EventWrapper
  static final Map<String, Map<int, List<_EventWrapper>>> _listeners = {};

  /// Sticky 缓存
  static final Map<String, Map<int, dynamic>> _sticky = {};

  /// 任务队列
  static final List<_EventTask> _queue = [];

  static bool _isProcessing = false;

  /// ==========================
  /// 注册（修复了类型赋值错误）
  /// ==========================
  static void on<T>({
    required String module, 
    required int eventID, 
    required EventCallback<T> callback, 
    EventToken? token, 
    bool sticky = false
  }) {
    final moduleMap = _listeners.putIfAbsent(module, () => {});
    final list = moduleMap.putIfAbsent(eventID, () => []);

    // 使用 originalCallback 进行重复检查
    if (list.any((e) => e.originalCallback == callback)) {
      RxDebug.log('⚠️ [$module] 重复注册 $eventID');
      return;
    }

    // 【核心修复】：包装回调，手动进行类型转换 (data as T)
    final wrapper = _EventWrapper(
      wrapperCallback: (id, uuid, data) async {
        return await callback(id, uuid, data as T);
      },
      originalCallback: callback,
      token: token,
    );

    list.add(wrapper);

    /// Sticky 立即回调
    if (sticky && _sticky[module]?[eventID] != null) {
      final stickyData = _sticky[module]![eventID];
      Future.microtask(() {
        try {
          callback(eventID, "sticky", stickyData as T);
        } catch (e) {
          RxDebug.log('❌ Sticky 回调类型转换失败: $e');
        }
      });
    }
  }

  /// ==========================
  /// 发送事件
  /// ==========================
  static void emit<T>({
    required String module,
    required int eventID,
    required T data,
    String uuid = "",
    EventPriority priority = EventPriority.normal,
    bool parallel = true,
    bool sticky = false,
    Duration? delay,
  }) {
    if (sticky) {
      _sticky.putIfAbsent(module, () => {})[eventID] = data;
    }

    final task = _EventTask(
      module: module, 
      eventID: eventID, 
      data: data, 
      uuid: uuid, 
      priority: priority, 
      parallel: parallel
    );

    if (delay != null) {
      Future.delayed(delay, () => _enqueue(task));
    } else {
      _enqueue(task);
    }
  }

  static void _enqueue(_EventTask task) {
    _queue.add(task);
    // 稳定排序：优先级高的在前
    _queue.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    _processQueue();
  }

  static void _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      final listeners = _listeners[task.module]?[task.eventID];
      if (listeners == null || listeners.isEmpty) continue;

      RxDebug.log("🚀 分发事件 ${task.eventID} (${task.priority})");

      if (task.parallel) {
        await Future.wait(
          listeners.map((e) async {
            try {
              // 调用包装后的回调
              await e.wrapperCallback(task.eventID, task.uuid, task.data);
            } catch (e, s) {
              RxDebug.log('❌ 并发执行错误: $e\n$s');
            }
          }),
        );
      } else {
        for (final e in List.from(listeners)) {
          try {
            await e.wrapperCallback(task.eventID, task.uuid, task.data);
          } catch (e, s) {
            RxDebug.log('❌ 串行执行错误: $e\n$s');
          }
        }
      }
    }

    _isProcessing = false;
  }

  /// ==========================
  /// 移除（通过 originalCallback 匹配）
  /// ==========================
  static void off({required String module, required int eventID, dynamic callback}) {
    final list = _listeners[module]?[eventID];
    if (list == null) return;

    if (callback == null) {
      list.clear();
    } else {
      list.removeWhere((e) => e.originalCallback == callback);
    }
  }

  static void offByToken(EventToken token) {
    for (final moduleMap in _listeners.values) {
      for (final list in moduleMap.values) {
        list.removeWhere((e) => e.token == token);
      }
    }
    RxDebug.log('🗑️ 已通过 Token 移除监听器');
  }

  static void clearAll() {
    _listeners.clear();
    _sticky.clear();
    _queue.clear();
    RxDebug.log('🧼 已清空事件总线');
  }
}