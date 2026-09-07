# Core Summary of rxflare

rxflare is a **lightweight reactive state management library for Flutter**, focused on **automatic dependency tracking, field-level precise updates, low boilerplate, and high performance**.

---

## 1. Core Positioning

* A minimalist reactive state management solution with **zero configuration, automatic dependency tracking, and partial widget rebuilding**
* Designed as a lightweight alternative to Provider, GetX, Bloc, and other heavier solutions
* Ideal for rapid development in small to medium-sized Flutter projects
### Core idea
* obs → reactive primitives (int, String, bool)
* obsMap / obsList / obsSet → reactive collections
* Rx(() => UI) → automatic dependency tracking
* Field-level updates → only affected UI rebuilds
---

## 2. Key Features (Must-Know)

### 1. Automatic Dependency Tracking

Using `.obs` variables together with `Rx(() => Widget)`, dependencies are tracked automatically and widgets rebuild only when necessary.

### 2. Field-/Index-Level Precise Updates

Supports granular listening and updates for:

* `Map` by key
* `List` by index

Only the affected UI parts are rebuilt, maximizing rendering performance.

### 3. Computed Properties

`computed()` enables automatic chained dependency updates, keeping derived state synchronized in real time.

### 4. Event Bus (`RxEventBus`)

Provides:

* Module-based events
* ID-based subscriptions
* Priority handling
* Sticky events
* Serial/parallel execution
* Batch unsubscription

### 5. Async Wrapper (`RxFuture`)

Built-in handling for:

* Loading state
* Error state
* Success state

Simplifies asynchronous UI development.

### 6. Dependency Management (`RxDI` + `RxProvider`)

Supports:

* Singleton instances
* Lazy loading
* Multiple instances
* Page-level isolation

Works well with controller-based architectures.

### 7. Routing (`rxr`)

Supports:

* Path parameters
* Query parameters
* Object passing
* Returning results between pages

### 8. Routing (RxMaterialApp + rxr)
* RxFlare provides a lightweight Navigator 2.0 based routing system with support for path parameters, query parameters, object passing, and page result returning.
* 1. Recommended: RxMaterialApp
* RxMaterialApp is the official convenient wrapper. It automatically handles route registration and router setup, so you don't need to manually write routerDelegate, routeInformationParser, or call rxr.register().
```flutter
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return   // Your reactive wrapper
       RxMaterialApp(
        routes: AppRoutes.routes,   // Auto registered
        initialRoute: "/",  //default
       
    );
  }
}
```
* 2. Define Routes
```flutter 
class AppRoutes {
  static final Map<String, RxRoute> routes = {
    '/': RxRoute(builder: () => const HomePage()),
    '/login': RxRoute(builder: () => const LoginPage()),
    '/detail/:id': RxRoute(builder: () => const DetailPage()),
    '/profile': RxRoute(
      builder: () => const ProfilePage(),
      guard: () async => await checkLogin(), // Optional guard
    ),
  };
}
```
* 3. Navigation & Parameters
```flutter
// Navigate
rxr.to('/detail/123?type=hot', arguments: MyData());

// Get parameters (inside target page)
final id = rxr.param('id');           // Path parameter
final type = rxr.queryItem('type');   // Query parameter
final obj = rxr.args<MyData>();       // Custom object

// Navigate with result
final result = await rxr.to<String>('/edit');
print(result);

// Go back with result
rxr.back(result: "Saved successfully");
```
* RxMaterialApp Parameters
* RxMaterialApp forwards most properties of MaterialApp.router:

* routes (required)
* initialRoute (default: "/")
* theme, darkTheme, themeMode
* builder
* localizationsDelegates, supportedLocales
* debugShowCheckedModeBanner
* title, color, scrollBehavior, scaffoldMessengerKey, etc.

### 9. Automatic Disposal (`RxAutoDispose`)

Helps prevent memory leaks and reduces cleanup boilerplate.

---

## 3. Core API Overview

* Reactive variable: `xxx.obs`
* Auto-rebuild widget: `Rx(() => Text('${count.value}'))`
* Manual dependency specification: `Rx.custom(deps: [count], builder: ...)`
* Computed property: `computed(() => a.value + b.value)`
* Precise Map/List updates: `updateField` / `updateAt` / `getItem`
* Events: `RxEventBus.on / notify / off`
* Async handling: `RxFuture`
* Dependency management: `RxDI.put / find` + `RxProvider`
* Routing: `rxr.to / back / param / queryItem`

---

## 4. Best Use Cases

* Rapid Flutter page development with minimal boilerplate
* Large forms and lists requiring **fine-grained partial updates** for better performance
* Small to medium-sized projects that want to avoid overly complex state management frameworks
* Business scenarios involving:

  * Event communication
  * Async state handling
  * Controller isolation

---

## 5. One-Sentence Highlight

**Achieve highly precise UI updates with minimal code — powered by automatic dependency tracking and field-level reactive updates for both simplicity and performance.**

## Apps in Production (Google Play)

`rxflare` is battle-tested in real-world applications available on Google Play:

* **Countdown Widget‑Days Reminder** — Leverages `rxflare` for precise state synchronization and low-overhead UI updates.
* **easynote** — Utilizes field-level reactive updates (`getItem` / `updateField`) to handle efficient note listing and content dynamic updates.
# screenshot

<p align="center">
  <img src="https://github.com/msfm2018/rxflare/blob/1.4.0/img/0.png?raw=true" width="45%"> 
  <img src="https://github.com/msfm2018/rxflare/blob/1.4.0/img/index.png?raw=true" width="45%"> 

</p>

## 相关软件 
  <a >音乐 https://github.com/msfm2018/localMusicPlay</a>
  <a> 树管理 https://github.com/msfm2018/simple_tree </a>


##  the most basic usage (automatic dependency)
```flutter
final count = 0.obs;

Rx(() => Text("计数: ${count.value}"));

FloatingActionButton(
  onPressed: () => count.value++,
  child: Icon(Icons.add),
)

```
## One Rx block listens to multiple values.
```
final name = "张三".obs;
final age = 20.obs;
final score = 100.obs;

Rx(() => Text('${name.value}，${age.value}岁，分数 ${score.value}'));
```


## Map+Field Level Update (Core Competence)

```
final user = {
  "name": "张三",
  "age": 25,
  "avatar": "xxx"
}.obs;

// 只监听 name 变化
Rx(() => Text("姓名: ${user.getItem('name')}"));

// 只监听 age 变化
Rx(() => Text("年龄: ${user.getItem('age')}"));

// 精准更新某个字段
user.updateField("name", "李四");   // 仅 name 的 Rx 重绘
```

## List + index accurate update
```
final items = List.generate(1000, (i) => {
  "id": i,
  "title": "Item $i",
  "score": 50,
}).obsListMap;

// 只更新第5项
items.updateAt(5, {...items[5], "score": 999});


final list = ["A", "B", "C"].obs;

Rx(() => Text("Item 1: ${list.getItem(1)}"));

list.updateField(1, "🔥B 已修改"); // 仅刷新第2项
```
## Manual dependency mode (Rx.custom you wrote)

```
class DemoPage5 extends StatelessWidget {
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

```

## Field Level Dependency (Your Advanced Function)
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
## The most basic computed
```
final price = 99.obs;
final quantity = 1.obs;

// 计算属性会自动追踪依赖
late final total = computed(() => price.value * quantity.value);
late final isExpensive = computed(() => total.value > 500);

Rx(() => Column(
  children: [
    Text("总价: ${total.value} 元", style: const TextStyle(fontSize: 32)),
    Text(isExpensive.value ? "💰 高消费" : "🛍️ 性价比不错",
         style: TextStyle(color: isExpensive.value ? Colors.red : Colors.green)),
  ],
));


final count = RxState<int>(1);

final doubleCount = computed(() => count.value * 2);

print(doubleCount.value); // 2

count.value = 5;

print(doubleCount.value); // 10（自动更新）

```
## Multiple Dependencies
```
final a = RxState<int>(2);

final b = computed(() => a.value * 2);
final c = computed(() => b.value + 1);

print(c.value); // 5

a.value = 10;

print(c.value); // 21
```
## Dependency Dynamic Change
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
## Chain computed
```final a = RxState<int>(2);

final b = computed(() => a.value * 2);
final c = computed(() => b.value + 1);

print(c.value); // 5

a.value = 10;

print(c.value); // 21
```
# RxEventBus
## Basic use (simplest)
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
## RxFuture
```
late RxFuture<User> userFuture = RxFuture(() async {
  await Future.delayed(const Duration(seconds: 2));
  return User(name: "张三");
});

Rx(() {
  if (userFuture.isInitialLoading) return const CircularProgressIndicator();
  if (userFuture.hasError) return Text("错误: ${userFuture.error}");
  return Text("用户: ${userFuture.data?.name}");
});


final isLoading = false.obs;
final songs = <MediaItem>[].obs;

Future<void> loadMusic() async {
  await songs.runAsyncWithStatus(
    onLoading: (loading) {
      isLoading.value = loading;
    },
    onError: (error) {
      print("加载失败: $error");
    },
    asyncAction: () async {
      return await repo.loadMusic();
    },
  );
}


Future<void> loadMusic() async {
  await songs.runAsync(
    retryCount: 3,
    retryDelay: const Duration(seconds: 1),

    onLoading: (loading) {
      isLoading.value = loading;
    },

    onError: (error) {
      print("最终失败: $error");
    },

    asyncAction: () async {
      return await repo.loadMusic();
    },
  );
}
```
## Strongly typed (generic T)
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
## Cancel listening (off)
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
## Bulk removal using Token (recommended)
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
## Sticky event (you can also receive it after registration)
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
#### 6. 优先级（high / normal / low）
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
## Serial vs parallel
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
## Load User Information Page
```
late RxFuture<String> userRx;

userRx = RxFuture(() async {
  await Future.delayed(const Duration(seconds: 2));
  return "用户数据加载成功";
});

if (userRx.isInitialLoading) return const CircularProgressIndicator();
if (userRx.hasError) return Text("错误: ${userRx.error}");

Text(userRx.data ?? "");
```
### RxDI + RxProvider
#### 最基础用法（手动 put / find）
```
class UserController {
  String name = "Tom";
}

void main() {
  // 注册
  RxDI.put(UserController());

  // 获取
  final c = RxDI.find<UserController>();
  print(c.name); // Tom
}
```
#### 2. 懒加载（lazyPut）
```
class ApiService {
  ApiService() {
    print("ApiService 创建了");
  }
}

void main() {
  RxDI.lazyPut<ApiService>(() => ApiService());

  // 此时还没创建

  final api = RxDI.find<ApiService>();
  // 👉 这里才真正创建

  final api2 = RxDI.find<ApiService>();
  // 👉 不会重复创建（单例）
}
```
#### 3. 多实例（name 区分）
```
class Counter {
  int value = 0;
}

void main() {
  RxDI.put(Counter(), name: "A");
  RxDI.put(Counter(), name: "B");

  final a = RxDI.find<Counter>(name: "A");
  final b = RxDI.find<Counter>(name: "B");

  a.value = 10;
  b.value = 20;

  print(a.value); // 10
  print(b.value); // 20
}
```
#### 4 Flutter 实战
```
RxProvider + Controller（中大型项目推荐架构）

class UserController implements Disposable {
  final count = 0.obs;
  late final RxFuture<User> userFuture;

  UserController() {
    userFuture = RxFuture(() async { ... });
  }

  void increment() => count.value++;

  @override
  void dispose() {
    userFuture.dispose();
    count.dispose();
    print("UserController 已释放");
  }
}

/// ====================== Page ======================
class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RxProvider<UserController>(
      dependency: UserController(),
      child: const UserView(),
    );
  }
}

class UserView extends StatefulWidget {
  const UserView({super.key});
  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  late UserController controller;

  @override
  void initState() {
    super.initState();
    controller = RxDI.find<UserController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Rx(() => Text('计数: ${controller.count.value}')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}

简单释放 RxAutoDispose

class _UserPageState extends State<UserPage> with RxAutoDispose {
  final count = 0.obs;
  late final RxFuture<User> userFuture;

  @override
  void initState() {
    super.initState();

    userFuture = RxFuture(() async { ... }).autoDispose(this);

    count.listen((v) => print(v)).autoDispose(this);
  }

  @override
  Widget build(BuildContext context) { ... }
}


多页隔离
RxProvider<CounterController>(
  name: "pageA",
  dependency: CounterController(),
  child: PageA(),
)

RxProvider<CounterController>(
  name: "pageB",
  dependency: CounterController(),
  child: PageB(),
)
获取
final cA = RxDI.find<CounterController>(name: "pageA");
final cB = RxDI.find<CounterController>(name: "pageB");

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
    return RxProvider<UserController>(
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
    c = RxDI.find<UserController>();

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

list.updateField(1, 999); //  触发
list.updateField(0, 111); //  不触发

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

 8. Form scene (Map+accurate update)
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

9. Advanced combination (similar to computed)

final a = RxState<int>(1);
final b = RxState<int>(2);

// 假设你有 RxComputed
// final sum = RxComputed(() => a.value + b.value);
```
# route

##  Define and register routes
```
rxr.register({
  '/home': RxRoute(builder: () => const HomePage(), path: '/home'),
  '/detail/:id': RxRoute(builder: () => const DetailPage(), path: '/detail/:id'),
});

// 跳转
rxr.to('/detail/123?type=hot', arguments: MyData());
rxr.off('/detail');
rxr.offAll('/detail');

// 获取参数
final id = rxr.param('id');        // 路径参数
final type = rxr.queryItem('type'); // query 参数
final obj = rxr.args<MyData>();     // 自定义对象

返回数据
final result = await rxr.to('/edit');
rxr.back(result: "保存成功");
```

##  Jump and parameter acquisition
```
// 跳转
rxr.to('/detail/123?type=premium', arguments: MyObject());

// 目标页获取参数
final id = rxr.param('id');        // '123'
final type = rxr.queryItem('type'); // 'premium'
final obj = rxr.args<MyObject>();   // 获取自定义对象
```
## Return and return the results.
```
// 发起跳转并等待
final result = await rxr.to('/settings');

// 目标页返回
rxr.back(result: 'Saved!');
```


### RxBuilder

```
RxBuilder(
  builder: (_) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return RxBuilder(
          builder: (_) {
            final isSelected = selectedIndex.value == index;
            return ListTile(
              title: Text(items[index]),
              tileColor: isSelected ? Colors.orange[100] : null,
            );
          },
        );
      },
    );
  },
);

```
## Internationalization (i18n)

RxFlare provides a lightweight built-in internationalization system.

Features:

- Automatic locale detection
- Reactive language switching
- Placeholder parameters
- Support for language + country code (`en_US`, `zh_CN`, etc.)

---

### 1. Define translations

Create a translation file:

`translations.dart`

```dart
final translations = {

  // ========== English ==========
  'en': {
    'hello': 'Hello',
    'welcome': 'Welcome to RxFlare',
    'count': 'Current count: {count}',
  },

  'en_US': {
    'hello': 'Hello',
    'welcome': 'Welcome to RxFlare',
    'count': 'Current count: {count}',
  },


  // ========== Simplified Chinese ==========
  'zh': {
    'hello': '你好',
    'welcome': '欢迎使用 RxFlare',
    'count': '当前计数：{count}',
  },

  'zh_CN': {
    'hello': '你好',
    'welcome': '欢迎使用 RxFlare',
    'count': '当前计数：{count}',
  },


  // ========== Traditional Chinese ==========
  'zh_TW': {
    'hello': '你好',
    'welcome': '歡迎使用 RxFlare',
    'count': '目前計數：{count}',
  },


  // ========== Japanese ==========
  'ja': {
    'hello': 'こんにちは',
    'welcome': 'RxFlareへようこそ',
    'count': '現在のカウント：{count}',
  },


  // ========== Korean ==========
  'ko': {
    'hello': '안녕하세요',
    'welcome': 'RxFlare에 오신 것을 환영합니다',
    'count': '현재 카운트: {count}',
  },


  // ========== German ==========
  'de': {
    'hello': 'Hallo',
    'welcome': 'Willkommen bei RxFlare',
    'count': 'Aktuelle Zählung: {count}',
  },


  // ========== French ==========
  'fr': {
    'hello': 'Bonjour',
    'welcome': 'Bienvenue sur RxFlare',
    'count': 'Compte actuel : {count}',
  },


  // ========== Spanish ==========
  'es': {
    'hello': 'Hola',
    'welcome': 'Bienvenido a RxFlare',
    'count': 'Recuento actual: {count}',
  },


  // ========== Portuguese ==========
  'pt': {
    'hello': 'Olá',
    'welcome': 'Bem-vindo ao RxFlare',
    'count': 'Contagem atual: {count}',
  },

};
```

---

### 2. Initialize localization

Initialize before `runApp`:

```dart
import 'translations.dart';


void main() {

  WidgetsFlutterBinding.ensureInitialized();


  RxLocale.init(
    translations: translations,
  );


  runApp(
    const MyApp(),
  );
}
```

---

### 3. Use translations

Use `.tr` for normal text:

```dart
Text(
  'hello'.tr,
)
```

The UI automatically updates when the locale changes.

---

### 4. Dynamic parameters

Translations support placeholders:

```dart
'count': 'Current count: {count}'
```

Use:

```dart
Text(
  'count'.trParams({
    'count': '10',
  }),
)
```

Output:

```
Current count: 10
```

---

### 5. Change language

Change locale dynamically:

```dart
// English
RxLocale.change(
  const RxLocale('en'),
);


// Simplified Chinese
RxLocale.change(
  const RxLocale(
    'zh',
    'CN',
  ),
);
```

All widgets using `.tr` will rebuild automatically.

---

### Complete example

```dart
class HomePage extends StatelessWidget {

  HomePage({super.key});


  final count = 0.obs;


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Rx(() => Text(
          'welcome'.tr,
        )),
      ),


      body: Center(

        child: Column(

          mainAxisAlignment:
          MainAxisAlignment.center,


          children: [

            Rx(() => Text(
              'hello'.tr,
              style: const TextStyle(
                fontSize: 28,
              ),
            )),


            Rx(() => Text(
              'count'.trParams({
                'count':
                '${count.value}',
              }),
            )),


            ElevatedButton(

              onPressed: () {
                count.value++;
              },

              child:
              const Text('+1'),

            ),

          ],
        ),
      ),
    );
  }
}
```

---

RxFlare i18n keeps the same reactive philosophy:

- `.tr` → reactive translation lookup
- `Rx(() => Widget)` → automatic rebuild
- `RxLocale.change()` → global language update

No additional localization delegate or generated files are required.
