// 定义事件类型（更通用）
import 'rx_debug.dart';

typedef EventCallback = void Function(int eventID, String uuid, Map<String, dynamic> data);

// 事件数据类
class EventListenData {
  final String moduleName;
  final int eventID;

  final EventCallback eventCallback;

  EventListenData({required this.moduleName, required this.eventID, required this.eventCallback});
}

// 按照模块来划分的事件管理器
class RxEvent {
  static final Map<String, List<EventListenData>> _moduleListeners = {};

  // 注册事件监听器
  static void putEventListen(String moduleName, int eventID, EventCallback callback) {
    final listeners = _moduleListeners.putIfAbsent(moduleName, () => []);

    // 避免重复注册
    if (listeners.any((e) => e.eventID == eventID)) {
      RxDebug.log('⚠️ [$moduleName] 已存在事件 ID: $eventID，忽略注册');
      return;
    }

    listeners.add(EventListenData(moduleName: moduleName, eventID: eventID, eventCallback: callback));
    RxDebug.log('✅ [$moduleName] 注册事件: $eventID');
  }

  // 按模块触发事件
  static void executeModuleEvent(String moduleName, int eventID, String uuid, Map<String, dynamic> data) {
    final listeners = _moduleListeners[moduleName];
    if (listeners == null) {
      RxDebug.log('❌ [$moduleName] 没有注册该事件监听器');
      return;
    }

    for (var listener in listeners) {
      if (listener.eventID == eventID) {
        listener.eventCallback(eventID, uuid, data);
      }
    }
  }

  // 移除事件监听器（按模块）
  static void removeEventListen(String module, int eventID) {
    final listeners = _moduleListeners[module];
    if (listeners == null) return;

    listeners.removeWhere((e) => e.eventID == eventID);
    if (listeners.isEmpty) _moduleListeners.remove(module);
    RxDebug.log('🗑️ [$module] 解绑事件: $eventID');
  }

  // 移除整个模块的监听器
  static void removeModule(String module) {
    if (_moduleListeners.containsKey(module)) {
      _moduleListeners.remove(module);
      RxDebug.log('🧹 已移除模块 [$module] 的所有监听器');
    }
  }

  // 清除所有监听器
  static void clearAll() {
    _moduleListeners.clear();
    RxDebug.log('🧼 所有事件监听器已清除');
  }
}
