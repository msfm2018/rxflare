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

```
# 一个 Rx 块 监听多个值
```
import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MultiRxDemo(),
    );
  }
}

class MultiRxDemo extends StatelessWidget {
  // 1. 定义三个响应式变量
  final name = "张三".obs;
  final age = 20.obs;
  final score = 100.obs;

  MultiRxDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RxFlare 自动依赖追踪')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 2. 只需要一个 Rx 块，就能同时监听 name, age, score
            // 只要其中任何一个值改变，这个 Text 就会自动重绘
            Rx(() {
              print("UI 重绘了！"); // 你可以观察控制台看它触发的时机
              return Text('${name.value} (年龄: ${age.value}) 的分数是: ${score.value}', style: const TextStyle(fontSize: 20));
            }),

            const SizedBox(height: 30),

            // 3. 修改数据的按钮
            ElevatedButton(onPressed: () => name.value = "李四", child: const Text('改名字')),
            ElevatedButton(onPressed: () => age.value++, child: const Text('长一岁')),
            ElevatedButton(onPressed: () => score.value -= 5, child: const Text('扣 5 分')),
          ],
        ),
      ),
    );
  }
}
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
# RxEventBus
# 1. 基础使用（最简单）
```
  // 注册监听
  RxEventBus.on<String>(
    module: "user",
    eventID: 1,
    callback: (eventID, uuid, data) async {
      print("收到事件: $data");
    },
  );

  // 发送事件
  RxEventBus.notify<String>(
    module: "user",
    eventID: 1,
    data: "Hello EventBus",
  );
```
# 2. 强类型（泛型 T）
```
class User {
  final String name;
  User(this.name);
}

void main() {
  RxEventBus.on<User>(
    module: "user",
    eventID: 2,
    callback: (id, uuid, user) async {
      print("用户: ${user.name}");
    },
  );

  RxEventBus.notify<User>(
    module: "user",
    eventID: 2,
    data: User("Tom"),
  );
}
```
# 3. 取消监听（off）
```
late EventCallback<String> cb;

void main() {
  cb = (id, uuid, data) async {
    print("监听: $data");
  };

  RxEventBus.on<String>(
    module: "test",
    eventID: 1,
    callback: cb,
  );

  RxEventBus.notify(module: "test", eventID: 1, data: "第一次");

  // 移除
  RxEventBus.off(
    module: "test",
    eventID: 1,
    callback: cb,
  );

  RxEventBus.notify(module: "test", eventID: 1, data: "第二次");
}
```
# 4. 使用 Token 批量移除（推荐）
```
void main() {
  final token = EventToken();

  RxEventBus.on<String>(
    module: "chat",
    eventID: 1,
    token: token,
    callback: (id, uuid, data) async {
      print("A: $data");
    },
  );

  RxEventBus.on<String>(
    module: "chat",
    eventID: 1,
    token: token,
    callback: (id, uuid, data) async {
      print("B: $data");
    },
  );

  RxEventBus.notify(module: "chat", eventID: 1, data: "hello");

  // 一键移除
  RxEventBus.offByToken(token);

  RxEventBus.notify(module: "chat", eventID: 1, data: "world");
}
```
# 5. Sticky 事件（后注册也能收到）
```
void main() {
  // 先发送（sticky）
  RxEventBus.notify<String>(
    module: "config",
    eventID: 1,
    data: "配置已加载",
    sticky: true,
  );

  // 后注册仍然会收到
  RxEventBus.on<String>(
    module: "config",
    eventID: 1,
    sticky: true,
    callback: (id, uuid, data) async {
      print("收到 sticky: $data");
    },
  );
}
```
# 6. 优先级（high / normal / low）
```
void main() {
  RxEventBus.on<String>(
    module: "priority",
    eventID: 1,
    callback: (id, uuid, data) async {
      print("执行: $data");
    },
  );

  RxEventBus.notify(
    module: "priority",
    eventID: 1,
    data: "普通",
    priority: EventPriority.normal,
  );

  RxEventBus.notify(
    module: "priority",
    eventID: 1,
    data: "高优先级",
    priority: EventPriority.high,
  );

  RxEventBus.notify(
    module: "priority",
    eventID: 1,
    data: "低优先级",
    priority: EventPriority.low,
  );
}
```
# 7. 串行 vs 并行
```
RxEventBus.on<String>(
  module: "task",
  eventID: 1,
  callback: (id, uuid, data) async {
    await Future.delayed(Duration(milliseconds: 500));
    print("任务1完成");
  },
);

RxEventBus.on<String>(
  module: "task",
  eventID: 1,
  callback: (id, uuid, data) async {
    await Future.delayed(Duration(milliseconds: 500));
    print("任务2完成");
  },
);

// 并行（默认）
RxEventBus.notify(
  module: "task",
  eventID: 1,
  data: "",
  parallel: true,
);

// 串行
RxEventBus.notify(
  module: "task",
  eventID: 1,
  data: "",
  parallel: false,
);
```
# RxFuture 
# 示例：加载用户信息页面
```
Future<String> fetchUser() async {
  await Future.delayed(const Duration(seconds: 2));

  // 模拟随机失败
  if (DateTime.now().second % 2 == 0) {
    throw Exception("网络错误");
  }

  return "用户：Tom (${DateTime.now()})";
}

class UserPage extends StatefulWidget {
  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late RxFuture<String> rx;

  @override
  void initState() {
    super.initState();
    rx = RxFuture(fetchUser);

    // 监听变化（假设 RxState 有 listen）
    rx.listen(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    rx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("RxFuture 示例")),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 🚀 1. 首次加载
    if (rx.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // ❌ 2. 完全失败（没有数据）
    if (rx.hasError && !rx.hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("加载失败: ${rx.error}"),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: rx.retry,
              child: const Text("重试"),
            )
          ],
        ),
      );
    }

    // ✅ 3. 有数据（核心）
    return RefreshIndicator(
      onRefresh: () async {
        rx.refresh();
      },
      child: ListView(
        children: [
          ListTile(
            title: Text(rx.data ?? ""),
            subtitle: _buildStatus(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    // 🔄 正在刷新
    if (rx.isRefreshing) {
      return const Text("正在刷新...");
    }

    // ⚠️ 软错误（有数据但更新失败）
    if (rx.hasSoftError) {
      return Text(
        "更新失败（显示旧数据）: ${rx.lastError}",
        style: const TextStyle(color: Colors.orange),
      );
    }

    // ♻️ 数据过期（stale）
    if (rx.isStale) {
      return const Text("数据更新中...");
    }

    return const Text("正常");
  }
}
```
# RxObjMgr + RxParent
# 最基础用法（手动 put / find）
```
class UserController {
  String name = "Tom";
}

void main() {
  // 注册
  RxObjMgr.put(UserController());

  // 获取
  final c = RxObjMgr.find<UserController>();
  print(c.name); // Tom
}
```
# 2. 懒加载（lazyPut）
```
class ApiService {
  ApiService() {
    print("ApiService 创建了");
  }
}

void main() {
  RxObjMgr.lazyPut<ApiService>(() => ApiService());

  // 此时还没创建

  final api = RxObjMgr.find<ApiService>();
  // 👉 这里才真正创建

  final api2 = RxObjMgr.find<ApiService>();
  // 👉 不会重复创建（单例）
}
```
# 3. 多实例（name 区分）
```
class Counter {
  int value = 0;
}

void main() {
  RxObjMgr.put(Counter(), name: "A");
  RxObjMgr.put(Counter(), name: "B");

  final a = RxObjMgr.find<Counter>(name: "A");
  final b = RxObjMgr.find<Counter>(name: "B");

  a.value = 10;
  b.value = 20;

  print(a.value); // 10
  print(b.value); // 20
}
```
# 4 Flutter 实战
```
class CounterController {
  int count = 0;

  void increment() {
    count++;
  }

  void dispose() {
    print("Controller 被释放");
  }
}
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RxParent<CounterController>(
      dependency: CounterController(),
      child: const CounterView(),
    );
  }
}
class CounterView extends StatefulWidget {
  const CounterView({super.key});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  late CounterController controller;

  @override
  void initState() {
    super.initState();
    controller = RxObjMgr.find<CounterController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DI 示例")),
      body: Center(
        child: Text("count: ${controller.count}"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            controller.increment();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
@override
void dispose() {
  final dynamic instance = RxObjMgr.find<T>(name: widget.name);
  instance.dispose?.call(); // 自动调用
  RxObjMgr.delete<T>(name: widget.name);
}

多页隔离
RxParent<CounterController>(
  name: "pageA",
  dependency: CounterController(),
  child: PageA(),
)

RxParent<CounterController>(
  name: "pageB",
  dependency: CounterController(),
  child: PageB(),
)
获取
final cA = RxObjMgr.find<CounterController>(name: "pageA");
final cB = RxObjMgr.find<CounterController>(name: "pageB");

结合 RxFuture（高级组合）
class UserController {
  late RxFuture<String> userRx;

  UserController() {
    userRx = RxFuture(() async {
      await Future.delayed(Duration(seconds: 1));
      return "用户数据";
    });
  }

  void dispose() {
    userRx.dispose();
  }
}
class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RxParent<UserController>(
      dependency: UserController(),
      child: const UserView(),
    );
  }
}
使用
class UserView extends StatefulWidget {
  const UserView({super.key});

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  late UserController c;

  @override
  void initState() {
    super.initState();
    c = RxObjMgr.find<UserController>();

    c.userRx.listen(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (c.userRx.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Text(c.userRx.data ?? ""),
    );
  }
}
```

#
```
final count = RxState<int>(0);

// 监听
final cancel = count.listen((v) {
  print("count: $v");
});

// 更新
count.value = 1;
count.update(2);

// 取消监听
cancel();
2. 带来源 ID（调试神器）
final state = RxState<int>(0, name: "counter");

state.listenWithId((value, id) {
  print("value: $value, 来自: $id");
});

state.value = 10;
state.refresh(); // 手动触发

3. Map 精准监听（🔥核心能力）
final user = RxState<Map<String, dynamic>>({
  "name": "Tom",
  "age": 20,
});

// 只监听 name
final cancel = user.listenByKey("name", (v) {
  print("name 变了: $v");
});

// 更新 name
user.updateField("name", "Jerry");

// 更新 age（不会触发）
user.updateField("age", 30);

4. List 精准监听
final list = RxState<List<int>>([1, 2, 3]);

list.listenByKey(1, (v) {
  print("index 1: $v");
});

list.updateField(1, 999); // ✅ 触发
list.updateField(0, 111); // ❌ 不触发

5. 条件监听（listenWhere）
final data = RxState<Map<String, dynamic>>({
  "score": 50,
});

data.listenWhere(
  (map) => map["score"] >= 60,
  (v) {
    print("是否及格: $v");
  },
);

data.updateField("score", 70);

6. 局部更新 vs 全局更新

final user = RxState<Map<String, dynamic>>({
  "name": "Tom",
  "age": 20,
});

user.listen((v) {
  print("全局更新: $v");
});

user.listenByKey("name", (v) {
  print("name 更新: $v");
});

// 默认：只触发 field
user.updateField("name", "Jerry");

// 强制触发全局
user.updateField("name", "Jack", notifyGlobal: true);

7. Flutter UI 实战
final counter = RxState<int>(0);
class RxDemoPage extends StatefulWidget {
  @override
  State<RxDemoPage> createState() => _RxDemoPageState();
}

class _RxDemoPageState extends State<RxDemoPage> {
  late VoidCallback cancel;

  @override
  void initState() {
    super.initState();

    cancel = counter.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    cancel();
    counter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("RxState Demo")),
      body: Center(
        child: Text("count: ${counter.value}"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          counter.value++;
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

8. 表单场景（Map + 精准更新）
final form = RxState<Map<String, dynamic>>({
  "username": "",
  "password": "",
});

监听单字段：
form.listenByKey("username", (v) {
  print("用户名输入: $v");
});

更新
form.updateField("username", "admin");

9. 高级组合（类似 computed）

final a = RxState<int>(1);
final b = RxState<int>(2);

// 假设你有 RxComputed
// final sum = RxComputed(() => a.value + b.value);
```
