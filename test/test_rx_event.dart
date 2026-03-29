import 'rx_event_bus.dart'; // 假设文件名是这个
import 'rx_debug.dart';

void main() async {
  // 1. 注册一个粘性事件监听 (模拟：用户打开 App 时还没登录)
  // 我们先 notify 一个粘性事件
  RxEventBus.notify<String>(
    module: "User",
    eventID: 1001,
    data: "这是登录前发送的缓存消息",
    sticky: true,
  );

  print("--- 准备注册监听器 ---");

  // 2. 注册监听器 (会立即触发上面的 sticky 消息)
  RxEventBus.on<String>(
    module: "User",
    eventID: 1001,
    sticky: true,
    callback: (id, uuid, data) async {
      print("【收到消息】ID: $id, 内容: $data");
    },
  );

  // 3. 测试优先级 (High 应该比 Normal 先执行)
  print("\n--- 测试优先级排序 ---");

  RxEventBus.on<String>(
    module: "Order",
    eventID: 2001,
    callback: (id, uuid, data) async {
      await Future.delayed(Duration(milliseconds: 100)); // 模拟耗时操作
      print("【订单处理】优先级: Normal, 数据: $data");
    },
  );

  // 发送一个普通优先级
  RxEventBus.notify<String>(
    module: "Order",
    eventID: 2001,
    data: "普通订单",
    priority: EventPriority.normal,
  );

  // 发送一个高优先级 (虽然它是后 notify 的，但在队列中会排到前面)
  RxEventBus.notify<String>(
    module: "Order",
    eventID: 2001,
    data: "🔥 紧急订单",
    priority: EventPriority.high,
  );

  // 4. 测试延迟发送
  RxEventBus.notify<String>(
    module: "User",
    eventID: 1002,
    data: "这是 2 秒后的延迟提醒",
    delay: Duration(seconds: 2),
  );

  RxEventBus.on<String>(
    module: "User",
    eventID: 1002,
    callback: (id, uuid, data) async {
      print("【延迟提醒】$data");
    },
  );

  print("--- 主流程执行完毕，等待异步任务 ---");
}
