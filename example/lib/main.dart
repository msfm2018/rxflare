import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

import 'auto_dispose/data_dispose.dart';
import 'dev_tool.dart';
import 'feature/features/home/controller/dio_controller.dart';
import 'feature/features/home/controller/home_controller.dart';
import 'feature/features/home/controller/page_controller.dart';
import 'feature/features/home/controller/poll_controller.dart';
import 'feature/features/home/controller/search_controller.dart';

import 'router_demo.dart';
import 'auto_dispose/auto_dispose.dart';
import 'showcase.dart';

final isDarkMode = false.obs;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 初始化 RxFlare 的 DevTools 扩展
  // 这样当应用启动时，服务扩展就已经在 VM Service 中准备就绪了
  RxObjMgr.initDevTools();
  // RxDebug.isEnabled = true;
  runApp(const RxFlareDemoApp());
}

class RxFlareDemoApp extends StatelessWidget {
  const RxFlareDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Rx(
      () => MaterialApp(
        title: 'RxFlare 完整演示',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 16, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RxFlare Core Features Demo'),
        actions: [
          // 暗黑模式切换按钮
          Rx(() => IconButton(icon: Icon(isDarkMode.value ? Icons.light_mode : Icons.dark_mode), onPressed: () => isDarkMode.value = !isDarkMode.value, tooltip: '切换主题')),
        ],
        bottom: TabBar(
          controller: _tabController,

          tabs: const [
            Tab(text: '基础自动追踪'),
            Tab(text: 'Map/List 精准'),
            Tab(text: 'Computed 计算'),
            Tab(text: 'EventBus 总线'),
            Tab(text: '性能测试'),
            Tab(text: '性能测试2'),
            Tab(text: '路由'),
            Tab(text: 'RxFuture用法'),
            Tab(text: 'RxFuture分页'),
            Tab(text: 'RxFuture轮询'),
            Tab(text: 'RxFuture防抖'),
            Tab(text: 'RxFutureDio'),

            Tab(text: '简单生命周期'),
            Tab(text: '复杂生命周期'),
            Tab(text: 'Showcase'),
            Tab(text: 'devtool'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BasicAutoTrackDemo(),
          MapListPreciseDemo(),
          ComputedDemo(),
          EventBusDemo(),
          PerformanceTestDemo(),
          PerformanceTestDemoA(),
          RouterDemo(),
          FreatureHomePage(),
          HomeP(),
          PollPage(),
          SearchPage(),
          DioPage(),
          AutoDisposePage(),
          DataDispose(),
          Showcase(),
          DevTool(),
        ],
      ),
    );
  }
}

// ==================== 1. 基础自动依赖追踪 ====================
class BasicAutoTrackDemo extends StatelessWidget {
  BasicAutoTrackDemo({super.key});

  final count = 0.obs;
  final name = "张三".obs;
  final isActive = true.obs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Rx(
            () => Column(
              children: [
                Text('姓名：${name.value}', style: const TextStyle(fontSize: 28)),
                Text('计数：${count.value}', style: const TextStyle(fontSize: 42, color: Colors.deepPurple)),
                Text('状态：${isActive.value ? "🟢 激活" : "🔴 关闭"}', style: const TextStyle(fontSize: 24)),
              ],
            ),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(onPressed: () => count.value++, child: const Icon(Icons.add)),
              const SizedBox(width: 20),
              FloatingActionButton(onPressed: () => name.value = name.value == "张三" ? "李四" : "张三", child: const Icon(Icons.person)),
              const SizedBox(width: 20),
              FloatingActionButton(onPressed: () => isActive.value = !isActive.value, child: const Icon(Icons.power_settings_new)),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== 2. Map/List 精准更新 ====================
class MapListPreciseDemo extends StatelessWidget {
  MapListPreciseDemo({super.key});

  final user = {"name": "Tom", "age": 25, "score": 88, "vip": true}.obs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Rx(() => Text("👤 姓名: ${user.getItem('name')}", style: const TextStyle(fontSize: 26))),
          const SizedBox(height: 12),
          Rx(() => Text("🎂 年龄: ${user.getItem('age')} 岁", style: const TextStyle(fontSize: 26))),
          const SizedBox(height: 12),
          Rx(() => Text("🏆 分数: ${user.getItem('score')}", style: const TextStyle(fontSize: 26, color: Colors.orange))),
          const SizedBox(height: 12),
          Rx(() => Text(user.getItem('vip') ? "💎 VIP 用户" : "普通用户", style: const TextStyle(fontSize: 26))),

          const SizedBox(height: 60),
          Wrap(
            spacing: 12,
            children: [
              ElevatedButton(onPressed: () => user.updateField("name", "Jerry"), child: const Text("改名")),
              ElevatedButton(onPressed: () => user.updateField("age", user.getItem("age") + 1), child: const Text("年龄+1")),
              ElevatedButton(onPressed: () => user.updateField("score", user.getItem("score") + 10), child: const Text("加分")),
              ElevatedButton(onPressed: () => user.updateField("vip", !user.getItem("vip")), child: const Text("切换VIP")),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== 3. Computed 计算属性 ====================
class ComputedDemo extends StatelessWidget {
  ComputedDemo({super.key});

  final price = 99.obs;
  final quantity = 1.obs;

  late final total = computed(() => price.value * quantity.value);
  late final isExpensive = computed(() => total.value > 500);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Rx(
        () => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🛒 商品购买", style: TextStyle(fontSize: 28)),
            const SizedBox(height: 30),
            Text("单价: ${price.value} 元", style: const TextStyle(fontSize: 24)),
            Text("数量: ${quantity.value}", style: const TextStyle(fontSize: 24)),
            const Divider(height: 40),
            Text("总价: ${total.value} 元", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text(isExpensive.value ? "💰 属于高消费！" : "🛍️ 性价比不错", style: TextStyle(fontSize: 24, color: isExpensive.value ? Colors.red : Colors.green)),
          ],
        ),
      ),
    );
  }
}

// ==================== 4. RxEventBus 事件总线 ====================
class EventBusDemo extends StatefulWidget {
  const EventBusDemo({super.key});

  @override
  State<EventBusDemo> createState() => _EventBusDemoState();
}

class _EventBusDemoState extends State<EventBusDemo> {
  final List<String> messages = [];
  final token = EventToken();

  @override
  void initState() {
    super.initState();
    // 注册事件监听
    RxEventBus.on<String>(
      module: "chat",
      eventID: 1001,
      token: token,
      callback: (id, uuid, data) async {
        setState(() {
          messages.add("收到消息: $data");
        });
      },
    );
  }

  @override
  void dispose() {
    RxEventBus.offByToken(token); // 清理
    super.dispose();
  }

  void sendMessage() {
    final text = "你好，这是第 ${messages.length + 1} 条消息";
    RxEventBus.notify<String>(module: "chat", eventID: 1001, data: text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(onPressed: sendMessage, icon: const Icon(Icons.send), label: const Text("发送消息")),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) => ListTile(leading: const Icon(Icons.message), title: Text(messages[index])),
          ),
        ),
      ],
    );
  }
}

// // ==================== 5. 性能测试页 ====================
class PerformanceTestDemoA extends StatefulWidget {
  const PerformanceTestDemoA({super.key});

  @override
  State<PerformanceTestDemoA> createState() => _PerformanceTestDemoStateA();
}

class _PerformanceTestDemoStateA extends State<PerformanceTestDemoA> {
  final items = List.generate(1000, (i) => {"id": i, "title": "Item $i", "score": 50 + (i % 50)}).obs;

  final totalRebuildCount = 0.obs; // 整个页面重绘次数
  final updateCount = 0.obs;

  void updateRandomItem() {
    final randomIndex = DateTime.now().millisecond % 1000;
    final current = items.getItem(randomIndex);
    //必须定义成  <String, Object>
    final newMap = <String, Object>{...current, "score": (current["score"] as int) + 10};

    items.updateField(randomIndex, newMap);

    updateCount.value++;

    print('🔥 更新了第 $randomIndex 项，分数 +10');
  }

  @override
  Widget build(BuildContext context) {
    totalRebuildCount.value++;
    print('📱 整个页面 build 执行次数: ${totalRebuildCount.value}');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text("列表项数量: 1000", style: Theme.of(context).textTheme.titleLarge),
              Rx(
                () => Text(
                  "页面 build 次数: ${totalRebuildCount.value}",
                  style: const TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Rx(() => Text("更新操作次数: ${updateCount.value}", style: const TextStyle(color: Colors.orange, fontSize: 16))),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: updateRandomItem, icon: const Icon(Icons.update), label: const Text("随机更新一项")),
              const SizedBox(height: 8),
              const Text("注意观察控制台：只有对应项的 Rx 会重绘", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: 1000,
            itemBuilder: (context, index) {
              return Rx(() {
                final item = items.getItem(index);
                // 每个 item 独立打印，证明颗粒化更新
                print('   🔄 Item $index 重绘了 → 分数=${item["score"]}');

                return ListTile(
                  dense: true,
                  title: Text(item["title"] as String),
                  subtitle: Text("分数: ${item["score"]}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Chip(
                    label: Text("+10", style: TextStyle(color: Theme.of(context).primaryColor)),
                    backgroundColor: Colors.deepPurple.withValues(alpha: .15),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }
}

// // ==================== 5. 性能测试页（使用 RxList 版）===================
// ==================== 5. 性能测试页（最终推荐版）===================
class PerformanceTestDemo extends StatefulWidget {
  const PerformanceTestDemo({super.key});

  @override
  State<PerformanceTestDemo> createState() => _PerformanceTestDemoState();
}

class _PerformanceTestDemoState extends State<PerformanceTestDemo> {
  final items = List.generate(1000, (i) => {"id": i, "title": "Item $i", "score": 50 + (i % 50)}).obsListMap; // 或 .obsList<Map<String, dynamic>>()

  final rebuildCount = 0.obs;
  final updateCount = 0.obs;

  void updateRandomItem() {
    final randomIndex = DateTime.now().millisecond % 1000;
    final current = items[randomIndex];

    // 推荐写法
    items.updateAt(randomIndex, {...current, "score": (current["score"] as num) + 10});

    // 也可以这样写（运算符重载，更简洁）
    // items[randomIndex] = {...current, "score": (current["score"] as num) + 10};
    print('🔥 更新了第 $randomIndex 项');
    updateCount.value++;
  }

  @override
  Widget build(BuildContext context) {
    rebuildCount.value++;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text("列表项数量: 1000", style: Theme.of(context).textTheme.titleLarge),
              Rx(
                () => Text(
                  "页面 build 次数: ${rebuildCount.value}",
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
              Rx(
                () => Text(
                  "更新次数: ${updateCount.value}",
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: updateRandomItem, icon: const Icon(Icons.update), label: const Text("随机更新一项")),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Rx(() {
                final item = items[index];
                return ListTile(title: Text(item["title"] ?? ''), subtitle: Text("分数: ${item["score"]}"));
              });
            },
          ),
        ),
      ],
    );
  }
}
