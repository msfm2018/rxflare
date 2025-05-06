import 'package:rxflare/rxflare.dart';

/// 示例用：全局状态
final counterState = RxState<int>(0, name: "CounterState");
final lastEventInfo = RxState<Map<String, dynamic>>({}, name: "LastEventInfo");

/// 事件 ID 常量
const int incrementEvent = 1;
const int decrementEvent = 2;

/// 用于注册所有事件绑定（只调用一次）
class RxEventBinder {
  static const String module = "CounterScreen";
  static bool _registered = false;

  static void bindAll() {
    if (_registered) return;
    _registered = true;

    RxEvent.putEventListen(module, incrementEvent, (eventID, uuid, data) {
      int amount = data["amount"] ?? 0;
      String source = data["source"] ?? "unknown";
      DateTime time = data["timestamp"] ?? DateTime.now();

      counterState.value += amount;
      lastEventInfo.value = {"type": "increment", "amount": amount, "source": source, "timestamp": time.toString()};
      RxDebug.log("✅ ➕ [$module] 来自 $source 增加 $amount @ $time -> ${counterState.value}");
    });

    RxEvent.putEventListen(module, decrementEvent, (eventID, uuid, data) {
      int amount = data["amount"] ?? 0;
      String source = data["source"] ?? "unknown";
      DateTime time = data["timestamp"] ?? DateTime.now();

      counterState.value -= amount;
      lastEventInfo.value = {"type": "decrement", "amount": amount, "source": source, "timestamp": time.toString()};
      RxDebug.log("✅ ➖ [$module] 来自 $source 减少 $amount @ $time -> ${counterState.value}");
    });
  }

  static void unbindAll() {
    RxEvent.removeModule(module);
    _registered = false;
  }
}
