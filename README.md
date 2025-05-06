#### 应用截图
<p align="center">
  <img src="https://github.com/msfm2018/rxflare/blob/0.0.1/index.png?raw=true">
</p>





## 数据定义

 import 'package:rxflare/rxflare.dart';

```数据定义
final greetingText = RxState("Hello");
final clickCounter = RxState(0);

final timestampedMessage = RxState("函数调用更新");

final fruits = RxState<List<String>>(["apple", "banana", "列表更新"]);

class StringChangeListenerWidget extends StatelessWidget {
  const StringChangeListenerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Rx(() => Text("Greeting: ${greetingText.value}")),
        Rx(() => Text("Timestamped: ${timestampedMessage.value}")),
        Rx(() => Text("Click Count: ${clickCounter.value}")),

        Rx(() => Text("First Fruit: ${fruits.value.isNotEmpty ? fruits.value[0] : ''}")),

        ElevatedButton(
          onPressed: () {
            fruits.updateField(0, "orange");
          },
          child: const Text("Update First Fruit"),
        ),
        ElevatedButton(
          onPressed: () {
            greetingText.value = '赋值更新';
            clickCounter.value++;
          },
          child: const Text("串赋值更新 与数字自增更新"),
        ),
        ElevatedButton(
          onPressed: () {
            timestampedMessage.update("Updated @ ${DateTime.now()}");
          },
          child: const Text("Update Timestamped Message"),
        ),
      ],
    );
  }
}
```

## 使用方法
```

  ```
