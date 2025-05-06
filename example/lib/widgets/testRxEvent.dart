//事件模块演示
import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
import 'rx_event_binder.dart';

class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    RxEventBinder.bindAll(); // 确保只注册一次监听器

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Rx(() => Text("Counter: ${counterState.value}", style: const TextStyle(fontSize: 24))),
          const SizedBox(height: 20),
          Rx(() {
            final info = lastEventInfo.value;
            if (info.isEmpty) return const Text("No event yet.");

            return Text(
              "📝 最近事件: ${info["type"]} | 来自: ${info["source"]} | 数量: ${info["amount"]} | 时间: ${info["timestamp"]}",
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            );
          }),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // 按模块触发事件
              RxEvent.executeModuleEvent("CounterScreen", incrementEvent, "button_click", {"amount": 1, "source": "increment_button", "timestamp": DateTime.now()});
            },
            child: const Text("Increment"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // 按模块触发事件
              RxEvent.executeModuleEvent("CounterScreen", decrementEvent, "button_click", {"amount": 1, "source": "decrement_button", "timestamp": DateTime.now()});
            },
            child: const Text("Decrement"),
          ),
        ],
      ),
    );
  }
}
