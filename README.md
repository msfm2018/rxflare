#### 应用截图
<p align="center">
  <img src="https://github.com/msfm2018/rxflare/blob/0.0.1/index.png?raw=true">
</p>





## 数据定义

 import 'package:rxflare/rxflare.dart';

```数据定义
final greetingText = RxValue("Hello");
final clickCounter = RxValue(0);

final timestampedMessage = RxValue("函数调用更新");

final fruits = RxValue<List<String>>(["apple", "banana", "列表更新"]);

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
异步数据
final RxFuture<User> userFuture = RxFuture(fetchUser());
Future<User> fetchUser() async {
  await Future.delayed(const Duration(seconds: 2));
  return User(name: '张三', age: 28);
}

Rx(() {
  final snapshot = userFuture.value;

  if (snapshot.connectionState == ConnectionState.waiting) {
    return const CircularProgressIndicator();
  } else if (snapshot.hasError) {
    return Text('加载失败: ${snapshot.error}');
  } else {
    return Text('用户名: ${snapshot.data}');
  }
});



自定义
Rx.custom(
  builder: () => Text(myState.value.toString()),
  deps: [myState],
)


  ```
