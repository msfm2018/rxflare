import 'dart:async';
import 'rx_debug.dart';

/// 事件优先级枚举
///
/// `high` > `normal` > `low`，用于决定事件分发顺序。
enum EventPriority { high, normal, low }

/// 事件回调函数类型
///
/// [T] 是事件数据类型。回调包含：
/// - [eventID] 事件 ID
/// - [uuid] 唯一标识
/// - [data] 事件数据
typedef EventCallback<T> = Future<void> Function(int eventID, String uuid, T data);

/// 事件标记，用于取消注册
///
/// 每个实例生成唯一 ID。
class EventToken {
  /// 唯一 ID
  final String id = DateTime.now().microsecondsSinceEpoch.toString();
}

/// 内部包装类，用于存储原始回调和包装后的回调
class _EventWrapper {
  /// 包装后的回调，统一存储 dynamic
  final Future<void> Function(int eventID, String uuid, dynamic data) wrapperCallback;

  /// 原始回调引用，用于 off() 时比对
  final dynamic originalCallback;

  /// 可选 Token
  final EventToken? token;

  _EventWrapper({required this.wrapperCallback, required this.originalCallback, this.token});
}

/// 内部事件任务
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
    required this.parallel,
  });
}

/// 全局事件总线
///
/// 提供事件注册、发送、Sticky 缓存、优先级和并发/串行分发。
///
/// 示例：
///
/// ```dart
/// final token = EventToken();
///
/// RxEventBus.on<String>(
///   module: 'chat',
///   eventID: 1,
///   token: token,
///   callback: (id, uuid, data) async {
///     print('收到事件 $id: $data');
///   },
/// );
///
/// RxEventBus.notify<String>(
///   module: 'chat',
///   eventID: 1,
///   data: 'Hello World',
/// );
///
/// // 移除事件
/// RxEventBus.offByToken(token);
/// ```
class RxEventBus {
  /// 注册表：模块 -> 事件ID -> 事件回调列表
  static final Map<String, Map<int, List<_EventWrapper>>> _listeners = {};

  /// Sticky 事件缓存
  static final Map<String, Map<int, dynamic>> _sticky = {};

  /// 任务队列
  static final List<_EventTask> _queue = [];

  /// 是否正在处理队列
  static bool _isProcessing = false;

  // =========================
  // 注册事件
  // =========================

  /// 注册事件回调
  ///
  /// [module] 模块名
  /// [eventID] 事件 ID
  /// [callback] 回调函数
  /// [token] 可选，用于 later 移除监听器
  /// [sticky] 是否启用 Sticky 回调（会立即回调最近的缓存事件）
  static void on<T>({
    required String module,
    required int eventID,
    required EventCallback<T> callback,
    EventToken? token,
    bool sticky = false,
  }) {
    final moduleMap = _listeners.putIfAbsent(module, () => {});
    final list = moduleMap.putIfAbsent(eventID, () => []);

    // 避免重复注册
    if (list.any((e) => e.originalCallback == callback)) {
      RxDebug.log(' [$module] 重复注册 $eventID');
      return;
    }

    // 包装回调，解决类型逆变
    final wrapper = _EventWrapper(
      wrapperCallback: (id, uuid, data) async {
        return await callback(id, uuid, data as T);
      },
      originalCallback: callback,
      token: token,
    );

    list.add(wrapper);

    // Sticky 回调
    if (sticky && _sticky[module]?[eventID] != null) {
      final stickyData = _sticky[module]![eventID];
      Future.microtask(() {
        try {
          callback(eventID, "sticky", stickyData as T);
        } catch (e) {
          RxDebug.log(' Sticky 回调类型转换失败: $e');
        }
      });
    }
  }

  // =========================
  // 发送事件
  // =========================

  /// 发送事件
  ///
  /// [module] 模块名
  /// [eventID] 事件 ID
  /// [data] 事件数据
  /// [uuid] 唯一标识，可选
  /// [priority] 事件优先级
  /// [parallel] 是否并发执行
  /// [sticky] 是否缓存为 Sticky 事件
  /// [delay] 延迟发送
  static void notify<T>({
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
      parallel: parallel,
    );

    if (delay != null) {
      Future.delayed(delay, () => _enqueue(task));
    } else {
      _enqueue(task);
    }
  }

  /// 内部入队
  static void _enqueue(_EventTask task) {
    _queue.add(task);
    // 优先级排序，高的在前
    _queue.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    _processQueue();
  }

  /// 内部处理队列
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
              await e.wrapperCallback(task.eventID, task.uuid, task.data);
            } catch (e, s) {
              RxDebug.log(' 并发执行错误: $e\n$s');
            }
          }),
        );
      } else {
        for (final e in List.from(listeners)) {
          try {
            await e.wrapperCallback(task.eventID, task.uuid, task.data);
          } catch (e, s) {
            RxDebug.log(' 串行执行错误: $e\n$s');
          }
        }
      }
    }

    _isProcessing = false;
  }

  // =========================
  // 移除事件
  // =========================

  /// 移除事件回调
  ///
  /// 如果 [callback] 为 null，则移除该模块该事件 ID 下所有回调
  static void off({required String module, required int eventID, dynamic callback}) {
    final list = _listeners[module]?[eventID];
    if (list == null) return;

    if (callback == null) {
      list.clear();
    } else {
      list.removeWhere((e) => e.originalCallback == callback);
    }
  }

  /// 通过 [EventToken] 移除监听器
  static void offByToken(EventToken token) {
    for (final moduleMap in _listeners.values) {
      for (final list in moduleMap.values) {
        list.removeWhere((e) => e.token == token);
      }
    }
    RxDebug.log('🗑️ 已通过 Token 移除监听器');
  }

  /// 清空所有事件和缓存
  static void clearAll() {
    _listeners.clear();
    _sticky.clear();
    _queue.clear();
    RxDebug.log('🧼 已清空事件总线');
  }
}
