import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

import 'auto_dispose/data_dispose.dart';
import 'error_boundary_demo.dart';
import 'feature/features/home/controller/dio_controller.dart';
import 'feature/features/home/controller/home_controller.dart';
import 'feature/features/home/controller/page_controller.dart';
import 'feature/features/home/controller/poll_controller.dart';
import 'feature/features/home/controller/search_controller.dart';

import 'router_demo.dart';
import 'auto_dispose/auto_dispose.dart';
import 'showcase.dart';
import 'translations.dart';

final isDarkMode = false.obs;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  RxLocale.init(
    translations: translations,
    // supported: RxLocale.supportedLocales,
  );
  // RxDebug.isEnabled = true;
  runApp(const RxFlareDemoApp());
}

class RxFlareDemoApp extends StatelessWidget {
  const RxFlareDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Rx(
      () => MaterialApp(
        title: 'app_title'.tr,
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
        title: Rx(() => Text('core_features_title'.tr)),
        actions: [
          // 暗黑模式切换按钮
          Rx(() => IconButton(icon: Icon(isDarkMode.value ? Icons.light_mode : Icons.dark_mode), onPressed: () => isDarkMode.value = !isDarkMode.value, tooltip: 'toggle_theme'.tr)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Rx(
            () => TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                Tab(text: 'tab_basic'.tr),
                Tab(text: 'tab_map_list'.tr),
                Tab(text: 'tab_computed'.tr),
                Tab(text: 'tab_eventbus'.tr),
                Tab(text: 'tab_performance'.tr),
                Tab(text: 'tab_performance2'.tr),
                Tab(text: 'tab_router'.tr),
                Tab(text: 'tab_rxfuture'.tr),
                Tab(text: 'tab_rxfuture_page'.tr),
                Tab(text: 'tab_rxfuture_poll'.tr),
                Tab(text: 'tab_rxfuture_debounce'.tr),
                Tab(text: 'tab_rxfuture_dio'.tr),
                Tab(text: 'tab_lifecycle_simple'.tr),
                Tab(text: 'tab_lifecycle_complex'.tr),
                Tab(text: 'tab_showcase'.tr),
                Tab(text: 'tab_error_boundary'.tr),
              ],
            ),
          ),
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
          ErrorBoundaryDemo(),
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
          // Rx(
          //   () => Column(
          //     children: [
          //       Text('姓名：${name.value}', style: const TextStyle(fontSize: 28)),
          //       Text('计数：${count.value}', style: const TextStyle(fontSize: 42, color: Colors.deepPurple)),
          //       Text('状态：${isActive.value ? "🟢 激活" : "🔴 关闭"}', style: const TextStyle(fontSize: 24)),
          //     ],
          //   ),
          // ),
          Rx(
            () => Column(
              children: [
                Text('name_label'.trParams({'name': name.value}), style: const TextStyle(fontSize: 28)),
                Text('count_label'.trParams({'count': '${count.value}'}), style: const TextStyle(fontSize: 42, color: Colors.deepPurple)),
                Text('status_label'.trParams({'status': isActive.value ? 'status_active'.tr : 'status_inactive'.tr}), style: const TextStyle(fontSize: 24)),
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
          Rx(() => Text('user_name'.trParams({'name': '${user.getItem('name')}'}), style: const TextStyle(fontSize: 26))),
          Rx(() => Text('user_age'.trParams({'age': '${user.getItem('age')}'}), style: const TextStyle(fontSize: 26))),
          Rx(() => Text('user_score'.trParams({'score': '${user.getItem('score')}'}), style: const TextStyle(fontSize: 26, color: Colors.orange))),
          Rx(() => Text(user.getItem('vip') ? 'user_vip'.tr : 'user_normal'.tr, style: const TextStyle(fontSize: 26))),
          const SizedBox(height: 60),
          Wrap(
            spacing: 12,
            children: [
              ElevatedButton(onPressed: () => user.updateField("name", "Jerry"), child: Text('btn_change_name'.tr)),
              ElevatedButton(onPressed: () => user.updateField("age", user.getItem("age") + 1), child: Text('btn_age_plus'.tr)),
              ElevatedButton(onPressed: () => user.updateField("score", user.getItem("score") + 10), child: Text('btn_add_score'.tr)),
              ElevatedButton(onPressed: () => user.updateField("vip", !user.getItem("vip")), child: Text('btn_toggle_vip'.tr)),
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
            Text('product_title'.tr, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 30),

            Text('unit_price'.trParams({'price': '${price.value}'}), style: const TextStyle(fontSize: 24)),
            Text('quantity'.trParams({'quantity': '${quantity.value}'}), style: const TextStyle(fontSize: 24)),

            const SizedBox(height: 20),

            /// 🔥 增加按钮（关键）
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: () => quantity.value--, child: const Text("➖")),
                const SizedBox(width: 20),
                ElevatedButton(onPressed: () => quantity.value++, child: const Text("➕")),
              ],
            ),

            const Divider(height: 40),

            Text('total_price'.trParams({'total': '${total.value}'}), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            Text(isExpensive.value ? 'high_consumption'.tr : 'good_value'.tr, style: TextStyle(fontSize: 24, color: isExpensive.value ? Colors.red : Colors.green)),
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
  // final List<String> messages = [];
  final messages = <String>[].obs;   // 改成响应式列表
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
         messages.add('received_message'.trParams({'msg': data}));
      },
    );
  }

  @override
  void dispose() {
    RxEventBus.offByToken(token); // 清理
    super.dispose();
  }

  void sendMessage() {
    final text = 'message_content'.trParams({'num': '${messages.length + 1}'});
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
          child:Rx(() => ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) => ListTile(leading: const Icon(Icons.message), title: Text(messages.value[index])),
          ),
        )),
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
              Text('list_item_count'.tr, style: Theme.of(context).textTheme.titleLarge),
              Rx(
                () => Text(
                  'page_build_count'.trParams({'count': '${totalRebuildCount.value}'}),
                  style: const TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Rx(() => Text('update_count'.trParams({'count': '${updateCount.value}'}), style: const TextStyle(color: Colors.orange, fontSize: 16))),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: updateRandomItem, icon: const Icon(Icons.update), label: Text('random_update'.tr)),
              const SizedBox(height: 8),
              Text('observe_console'.tr, style: TextStyle(color: Colors.grey)),
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
                  subtitle: Text('score_label'.trParams({'score': '${item["score"]}'}), style: const TextStyle(fontWeight: FontWeight.bold)),
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
