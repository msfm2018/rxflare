// 定义事件回调类型
typedef EventCallbackSimple = void Function(int eventID, Map<String, dynamic> data);

// 事件数据类
class EventListenSimpleData {
  final int eventID;
  final EventCallbackSimple eventCallback;

  EventListenSimpleData({required this.eventID, required this.eventCallback});
}

// 简化版事件总线
class RxSimpleEvent {
  static final List<EventListenSimpleData> _listeners = [];

  // 注册事件监听器
  static void putEventListen(int eventID, EventCallbackSimple callback) {
    print(eventID);
    _listeners.add(EventListenSimpleData(eventID: eventID, eventCallback: callback));
  }

  // 触发事件
  static void executeEvent(int eventID, Map<String, dynamic> data) {
    for (var listener in _listeners) {
      if (listener.eventID == eventID) {
        print("找到了 准备调用");
        listener.eventCallback(eventID, data);
      }
    }
  }

  // 移除事件监听器
  static void removeEventListen(int eventID) {
    _listeners.removeWhere((e) => e.eventID == eventID);
  }

  // 清除所有监听器
  static void clearAll() {
    _listeners.clear();
  }
}

// void main() {
//   // 注册事件监听器
//   RxSimpleEvent.putEventListen(1, (eventID, data) {
//     print('收到事件 $eventID，数据：$data');
//   });

//   // 触发事件
//   RxSimpleEvent.executeEvent(1, {'message': 'Hello, EventBus!'});

//   // 移除事件监听器
//   RxSimpleEvent.removeEventListen(1);

//   // 清除所有监听器
//   RxSimpleEvent.clearAll();
// }
