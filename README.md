#### 应用截图
<p align="center">
  <img src="https://github.com/msfm2018/rxflare/blob/1.1.3/img/index.png?raw=true">
    <img src="https://github.com/msfm2018/rxflare/blob/1.1.3/img/1.png?raw=true">
    <img src="https://github.com/msfm2018/rxflare/blob/1.1.3/img/2.png?raw=true">
    <img src="https://github.com/msfm2018/rxflare/blob/1.1.3/img/3.png?raw=true">
    <img src="https://github.com/msfm2018/rxflare/blob/1.1.3/img/4.png?raw=true">
</p>


#  Demo 1：最基础用法（自动依赖）
```


class DemoPage extends StatelessWidget {
  final count = 0.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Rx Demo")),
      body: Center(
        child: Rx(() {
          return Text(
            "count: ${count.value}",
            style: TextStyle(fontSize: 24),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          count.value++;
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
发生了什么？
build → 访问 count.value → 自动收集依赖
count.value++ → notify → Rx.refresh → setState
```
# Demo 2：多个状态自动依赖
```class DemoPage2 extends StatelessWidget {
  final count = 0.obs;
  final name = "Tom".obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Rx(() {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("count: ${count.value}"),
              Text("name: ${name.value}"),
            ],
          );
        }),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => count.value++,
            child: Icon(Icons.add),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => name.value = "Jerry",
            child: Icon(Icons.person),
          ),
        ],
      ),
    );
  }
}
```

# Demo 3：Map + 字段级更新（核心能力）

```class DemoPage3 extends StatelessWidget {
  final user = {
    "name": "Tom",
    "age": 20,
  }.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // 🔥 只依赖 name
            Rx(() {
              return Text(
                "name: ${user.getItem("name")}",
                style: TextStyle(fontSize: 22),
              );
            }),

            // 🔥 只依赖 age
            Rx(() {
              return Text(
                "age: ${user.getItem("age")}",
                style: TextStyle(fontSize: 22),
              );
            }),

          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              user.updateField("name", "Jerry");
            },
            child: Icon(Icons.person),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              user.updateField("age", 30);
            },
            child: Icon(Icons.cake),
          ),
        ],
      ),
    );
  }
}
点击 name 按钮 → 只刷新 name 的 Rx
点击 age 按钮 → 只刷新 age 的 Rx
```
# Demo 4：List + index 精准更新
```class DemoPage4 extends StatelessWidget {
  final list = ["A", "B", "C"].obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: List.generate(3, (index) {
          return Rx(() {
            return Text(
              "item $index: ${list.getItem(index)}",
              style: TextStyle(fontSize: 20),
            );
          });
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          list.updateField(1, "🔥B changed");
        },
        child: Icon(Icons.edit),
      ),
    );
  }
}只刷新 index=1 的那一行
```
# Demo 5：手动依赖模式（你写的 Rx.custom）

```class DemoPage5 extends StatelessWidget {
  final count = 0.obs;
  final name = "Tom".obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Rx.custom(
          deps: [count], // 👈 只监听 count
          builder: () {
            return Text(
              "count: ${count.value}, name: ${name.value}",
              style: TextStyle(fontSize: 20),
            );
          },
        ),
      ),
      floatingActionButton: Column(
        children: [
          FloatingActionButton(
            onPressed: () => count.value++,
            child: Icon(Icons.add),
          ),
          FloatingActionButton(
            onPressed: () => name.value = "Jerry",
            child: Icon(Icons.person),
          ),
        ],
      ),
    );
  }
}
count 变化 → 刷新
name 变化 → 不刷新
手动控制依赖
```

# 示例 1：field 级别依赖（你的高级功能🔥）
```​
// final user = RxState<Map<String, dynamic>>({
final user = RxState<Map>({
  "name": "Tom",
  "age": 18
});
final nameUpper = computed(() {
  return user.value["name"].toUpperCase();
});
print(nameUpper.value); // 输出 "TOM"
user.value = {...user.value, "name": "Jerry"};
print(nameUpper.value); // 输出 "JERRY"
```
# 示例 2：最基础 computed
```
final count = RxState<int>(1);

final doubleCount = computed(() => count.value * 2);

print(doubleCount.value); // 2

count.value = 5;

print(doubleCount.value); // 10（自动更新）

```
# 示例 3：多个依赖
```
final a = RxState<int>(2);

final b = computed(() => a.value * 2);
final c = computed(() => b.value + 1);

print(c.value); // 5

a.value = 10;

print(c.value); // 21
```
# 示例 4：依赖动态变化
```
final flag = RxState<bool>(true);
final a = RxState<int>(1);
final b = RxState<int>(100);

final result = computed(() {
  if (flag.value) {
    return a.value;
  } else {
    return b.value;
  }
});
print(result.value); // 1（依赖 a）

flag.value = false;
print(result.value); // 100（依赖变成 b）
```
# 示例 5：链式 computed
```final a = RxState<int>(2);

final b = computed(() => a.value * 2);
final c = computed(() => b.value + 1);

print(c.value); // 5

a.value = 10;

print(c.value); // 21
```

