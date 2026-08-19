// import 'package:flutter/material.dart';
// import 'package:rxflare/rxflare.dart';

// import 'auto_dispose/data_dispose.dart';
// import 'error_boundary_demo.dart';
// import 'feature/features/home/controller/dio_controller.dart';
// import 'feature/features/home/controller/home_controller.dart';
// import 'feature/features/home/controller/page_controller.dart';
// import 'feature/features/home/controller/poll_controller.dart';
// import 'feature/features/home/controller/search_controller.dart';

// import 'router_demo.dart';
// import 'auto_dispose/auto_dispose.dart';
// import 'showcase.dart';

// final isDarkMode = false.obs;

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 16, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Rx(() => Text('core_features_title'.tr)),
//         actions: [
//           TextButton(onPressed: () => RxLocale.setLocale(const Locale('zh')), child: Text("中文")),
//           TextButton(onPressed: () => RxLocale.setLocale(const Locale('en')), child: Text("English")),
//           TextButton(onPressed: () => RxLocale.setLocale(const Locale('ja')), child: Text("Japanese")),
//           Rx(() => Text(RxLocale.locale.languageCode)),
//           // 暗黑模式切换按钮
//           Rx(() => IconButton(icon: Icon(isDarkMode.value ? Icons.light_mode : Icons.dark_mode), onPressed: () => isDarkMode.value = !isDarkMode.value, tooltip: 'toggle_theme'.tr)),
//         ],
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(kToolbarHeight),
//           child: Rx(
//             () => TabBar(
//               controller: _tabController,
//               isScrollable: true,
//               tabs: [
//                 Tab(text: 'tab_basic'.tr),
//                 Tab(text: 'tab_map_list'.tr),
//                 Tab(text: 'tab_computed'.tr),
//                 Tab(text: 'tab_eventbus'.tr),
//                 Tab(text: 'tab_performance'.tr),
//                 Tab(text: 'tab_performance2'.tr),
//                 Tab(text: 'tab_router'.tr),
//                 Tab(text: 'tab_rxfuture'.tr),
//                 Tab(text: 'tab_rxfuture_page'.tr),
//                 Tab(text: 'tab_rxfuture_poll'.tr),
//                 Tab(text: 'tab_rxfuture_debounce'.tr),
//                 Tab(text: 'tab_rxfuture_dio'.tr),
//                 Tab(text: 'tab_lifecycle_simple'.tr),
//                 Tab(text: 'tab_lifecycle_complex'.tr),
//                 Tab(text: 'tab_showcase'.tr),
//                 Tab(text: 'tab_error_boundary'.tr),
//               ],
//             ),
//           ),
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           BasicAutoTrackDemo(),
//           MapListPreciseDemo(),
//           ComputedDemo(),
//           EventBusDemo(),
//           PerformanceTestDemo(),
//           PerformanceTestDemoA(),
//           MainTabWrapper(),
//           FreatureHomePage(),
//           HomeP(),
//           PollPage(),
//           SearchPage(),
//           DioPage(),
//           AutoDisposePage(),
//           DataDispose(),
//           Showcase(),
//           ErrorBoundaryDemo(),
//         ],
//       ),
//     );
//   }
// }

// // ==================== 1. 基础自动依赖追踪 ====================
// class BasicAutoTrackDemo extends StatelessWidget {
//   BasicAutoTrackDemo({super.key});

//   final count = 0.obs;
//   final name = "张三".obs;
//   final isActive = true.obs;

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Rx(
//           //   () => Column(
//           //     children: [
//           //       Text('姓名：${name.value}', style: const TextStyle(fontSize: 28)),
//           //       Text('计数：${count.value}', style: const TextStyle(fontSize: 42, color: Colors.deepPurple)),
//           //       Text('状态：${isActive.value ? "🟢 激活" : "🔴 关闭"}', style: const TextStyle(fontSize: 24)),
//           //     ],
//           //   ),
//           // ),
//           Rx(
//             () => Column(
//               children: [
//                 Text('name_label'.trParams({'name': name.value}), style: const TextStyle(fontSize: 28)),
//                 Text('count_label'.trParams({'count': '${count.value}'}), style: const TextStyle(fontSize: 42, color: Colors.deepPurple)),
//                 Text('status_label'.trParams({'status': isActive.value ? 'status_active'.tr : 'status_inactive'.tr}), style: const TextStyle(fontSize: 24)),
//               ],
//             ),
//           ),
//           const SizedBox(height: 60),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               FloatingActionButton(onPressed: () => count.value++, child: const Icon(Icons.add)),
//               const SizedBox(width: 20),
//               FloatingActionButton(onPressed: () => name.value = name.value == "张三" ? "李四" : "张三", child: const Icon(Icons.person)),
//               const SizedBox(width: 20),
//               FloatingActionButton(onPressed: () => isActive.value = !isActive.value, child: const Icon(Icons.power_settings_new)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ==================== 2. Map/List 精准更新 ====================
// class MapListPreciseDemo extends StatelessWidget {
//   MapListPreciseDemo({super.key});

//   final user = {"name": "Tom", "age": 25, "score": 88, "vip": true}.obs;

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Rx(() => Text('user_name'.trParams({'name': '${user.getItem('name')}'}), style: const TextStyle(fontSize: 26))),
//           Rx(() => Text('user_age'.trParams({'age': '${user.getItem('age')}'}), style: const TextStyle(fontSize: 26))),
//           Rx(() => Text('user_score'.trParams({'score': '${user.getItem('score')}'}), style: const TextStyle(fontSize: 26, color: Colors.orange))),
//           Rx(() => Text(user.getItem('vip') ? 'user_vip'.tr : 'user_normal'.tr, style: const TextStyle(fontSize: 26))),
//           const SizedBox(height: 60),
//           Wrap(
//             spacing: 12,
//             children: [
//               ElevatedButton(onPressed: () => user.updateField("name", "Jerry"), child: Text('btn_change_name'.tr)),
//               ElevatedButton(onPressed: () => user.updateField("age", user.getItem("age") + 1), child: Text('btn_age_plus'.tr)),
//               ElevatedButton(onPressed: () => user.updateField("score", user.getItem("score") + 10), child: Text('btn_add_score'.tr)),
//               ElevatedButton(onPressed: () => user.updateField("vip", !user.getItem("vip")), child: Text('btn_toggle_vip'.tr)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ==================== 3. Computed 计算属性 ====================
// class ComputedDemo extends StatelessWidget {
//   ComputedDemo({super.key});

//   final price = 99.obs;
//   final quantity = 1.obs;

//   late final total = computed(() => price.value * quantity.value);
//   late final isExpensive = computed(() => total.value > 500);

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Rx(
//         () => Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text('product_title'.tr, style: const TextStyle(fontSize: 28)),
//             const SizedBox(height: 30),

//             Text('unit_price'.trParams({'price': '${price.value}'}), style: const TextStyle(fontSize: 24)),
//             Text('quantity'.trParams({'quantity': '${quantity.value}'}), style: const TextStyle(fontSize: 24)),

//             const SizedBox(height: 20),

//             /// 🔥 增加按钮（关键）
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 ElevatedButton(onPressed: () => quantity.value--, child: const Text("➖")),
//                 const SizedBox(width: 20),
//                 ElevatedButton(onPressed: () => quantity.value++, child: const Text("➕")),
//               ],
//             ),

//             const Divider(height: 40),

//             Text('total_price'.trParams({'total': '${total.value}'}), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),

//             const SizedBox(height: 20),

//             Text(isExpensive.value ? 'high_consumption'.tr : 'good_value'.tr, style: TextStyle(fontSize: 24, color: isExpensive.value ? Colors.red : Colors.green)),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ==================== 4. RxEventBus 事件总线 ====================
// class EventBusDemo extends StatefulWidget {
//   const EventBusDemo({super.key});

//   @override
//   State<EventBusDemo> createState() => _EventBusDemoState();
// }

// class _EventBusDemoState extends State<EventBusDemo> {
//   // final List<String> messages = [];
//   final messages = <String>[].obs; // 改成响应式列表
//   final token = EventToken();

//   @override
//   void initState() {
//     super.initState();
//     // 注册事件监听
//     RxEventBus.on<String>(
//       module: "chat",
//       eventID: 1001,
//       token: token,
//       callback: (id, uuid, data) async {
//         messages.add('received_message'.trParams({'msg': data}));
//       },
//     );
//   }

//   @override
//   void dispose() {
//     RxEventBus.offByToken(token); // 清理
//     super.dispose();
//   }

//   void sendMessage() {
//     final text = 'message_content'.trParams({'num': '${messages.length + 1}'});
//     RxEventBus.notify<String>(module: "chat", eventID: 1001, data: text);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: ElevatedButton.icon(onPressed: sendMessage, icon: const Icon(Icons.send), label: const Text("发送消息")),
//         ),
//         const Divider(),
//         Expanded(
//           child: Rx(
//             () => ListView.builder(
//               itemCount: messages.length,
//               itemBuilder: (context, index) => ListTile(leading: const Icon(Icons.message), title: Text(messages.value[index])),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // // ==================== 5. 性能测试页 ====================
// class PerformanceTestDemoA extends StatefulWidget {
//   const PerformanceTestDemoA({super.key});

//   @override
//   State<PerformanceTestDemoA> createState() => _PerformanceTestDemoStateA();
// }

// class _PerformanceTestDemoStateA extends State<PerformanceTestDemoA> {
//   final items = List.generate(1000, (i) => {"id": i, "title": "Item $i", "score": 50 + (i % 50)}).obs;

//   final totalRebuildCount = 0.obs; // 整个页面重绘次数
//   final updateCount = 0.obs;

//   void updateRandomItem() {
//     final randomIndex = DateTime.now().millisecond % 1000;
//     final current = items.getItem(randomIndex);
//     //必须定义成  <String, Object>
//     final newMap = <String, Object>{...current, "score": (current["score"] as int) + 10};

//     items.updateField(randomIndex, newMap);

//     updateCount.value++;

//     print('🔥 更新了第 $randomIndex 项，分数 +10');
//   }

//   @override
//   Widget build(BuildContext context) {
//     totalRebuildCount.value++;
//     print('📱 整个页面 build 执行次数: ${totalRebuildCount.value}');

//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               Text('list_item_count'.tr, style: Theme.of(context).textTheme.titleLarge),
//               Rx(
//                 () => Text(
//                   'page_build_count'.trParams({'count': '${totalRebuildCount.value}'}),
//                   style: const TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               Rx(() => Text('update_count'.trParams({'count': '${updateCount.value}'}), style: const TextStyle(color: Colors.orange, fontSize: 16))),
//               const SizedBox(height: 16),
//               ElevatedButton.icon(onPressed: updateRandomItem, icon: const Icon(Icons.update), label: Text('random_update'.tr)),
//               const SizedBox(height: 8),
//               Text('observe_console'.tr, style: TextStyle(color: Colors.grey)),
//             ],
//           ),
//         ),
//         const Divider(),
//         Expanded(
//           child: ListView.builder(
//             itemCount: 1000,
//             itemBuilder: (context, index) {
//               return Rx(() {
//                 final item = items.getItem(index);
//                 // 每个 item 独立打印，证明颗粒化更新
//                 print('   🔄 Item $index 重绘了 → 分数=${item["score"]}');

//                 return ListTile(
//                   dense: true,
//                   title: Text(item["title"] as String),
//                   subtitle: Text('score_label'.trParams({'score': '${item["score"]}'}), style: const TextStyle(fontWeight: FontWeight.bold)),
//                   trailing: Chip(
//                     label: Text("+10", style: TextStyle(color: Theme.of(context).primaryColor)),
//                     backgroundColor: Colors.deepPurple.withValues(alpha: .15),
//                   ),
//                 );
//               });
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }

// // // ==================== 5. 性能测试页（使用 RxList 版）===================
// // ==================== 5. 性能测试页（最终推荐版）===================
// class PerformanceTestDemo extends StatefulWidget {
//   const PerformanceTestDemo({super.key});

//   @override
//   State<PerformanceTestDemo> createState() => _PerformanceTestDemoState();
// }

// class _PerformanceTestDemoState extends State<PerformanceTestDemo> {
//   final items = List.generate(1000, (i) => {"id": i, "title": "Item $i", "score": 50 + (i % 50)}).obsListMap; // 或 .obsList<Map<String, dynamic>>()

//   final rebuildCount = 0.obs;
//   final updateCount = 0.obs;

//   void updateRandomItem() {
//     final randomIndex = DateTime.now().millisecond % 1000;
//     final current = items[randomIndex];

//     // 推荐写法
//     items.updateAt(randomIndex, {...current, "score": (current["score"] as num) + 10});

//     // 也可以这样写（运算符重载，更简洁）
//     // items[randomIndex] = {...current, "score": (current["score"] as num) + 10};
//     print('🔥 更新了第 $randomIndex 项');
//     updateCount.value++;
//   }

//   @override
//   Widget build(BuildContext context) {
//     rebuildCount.value++;

//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               Text("列表项数量: 1000", style: Theme.of(context).textTheme.titleLarge),
//               Rx(
//                 () => Text(
//                   "页面 build 次数: ${rebuildCount.value}",
//                   style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               Rx(
//                 () => Text(
//                   "更新次数: ${updateCount.value}",
//                   style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton.icon(onPressed: updateRandomItem, icon: const Icon(Icons.update), label: const Text("随机更新一项")),
//             ],
//           ),
//         ),
//         const Divider(),
//         Expanded(
//           child: ListView.builder(
//             itemCount: items.length,
//             itemBuilder: (context, index) {
//               return Rx(() {
//                 final item = items[index];
//                 return ListTile(title: Text(item["title"] ?? ''), subtitle: Text("分数: ${item["score"]}"));
//               });
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:rxflare/rxflare.dart';

// import 'auto_dispose/auto_dispose.dart';
// import 'auto_dispose/data_dispose.dart';
// import 'error_boundary_demo.dart';
// import 'feature/features/home/controller/dio_controller.dart';
// import 'feature/features/home/controller/home_controller.dart';
// import 'feature/features/home/controller/page_controller.dart';
// import 'feature/features/home/controller/poll_controller.dart';
// import 'feature/features/home/controller/search_controller.dart';

// import 'router_demo.dart';
// import 'showcase.dart';

// final isDarkMode = false.obs;

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 16, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         elevation: 0,
//         centerTitle: false,
//         title: Rx(
//           () => Text(
//             'core_features_title'.tr,
//             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
//           ),
//         ),
//         actions: [
//           // 语言选择 PopMenu
//           PopupMenuButton<String>(
//             icon: const Icon(Icons.language),
//             tooltip: 'Language',
//             onSelected: (locale) => RxLocale.setLocale(Locale(locale)),
//             itemBuilder: (context) => const [
//               PopupMenuItem(value: 'zh', child: Text("中文")),
//               PopupMenuItem(value: 'en', child: Text("English")),
//               PopupMenuItem(value: 'ja', child: Text("日本語")),
//             ],
//           ),
//           // 暗黑模式切换按钮
//           Rx(
//             () => IconButton(
//               icon: Icon(isDarkMode.value ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
//               onPressed: () => isDarkMode.value = !isDarkMode.value,
//               tooltip: 'toggle_theme'.tr,
//             ),
//           ),
//           const SizedBox(width: 8),
//         ],
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(48),
//           child: Rx(
//             () => TabBar(
//               controller: _tabController,
//               isScrollable: true,
//               tabAlignment: TabAlignment.start,
//               indicatorSize: TabBarIndicatorSize.label,
//               dividerColor: Colors.transparent,
//               labelStyle: const TextStyle(fontWeight: FontWeight.bold),
//               unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
//               tabs: [
//                 Tab(text: 'tab_basic'.tr),
//                 Tab(text: 'tab_map_list'.tr),
//                 Tab(text: 'tab_computed'.tr),
//                 Tab(text: 'tab_eventbus'.tr),
//                 Tab(text: 'tab_performance'.tr),
//                 Tab(text: 'tab_performance2'.tr),
//                 Tab(text: 'tab_router'.tr),
//                 Tab(text: 'tab_rxfuture'.tr),
//                 Tab(text: 'tab_rxfuture_page'.tr),
//                 Tab(text: 'tab_rxfuture_poll'.tr),
//                 Tab(text: 'tab_rxfuture_debounce'.tr),
//                 Tab(text: 'tab_rxfuture_dio'.tr),
//                 Tab(text: 'tab_lifecycle_simple'.tr),
//                 Tab(text: 'tab_lifecycle_complex'.tr),
//                 Tab(text: 'tab_showcase'.tr),
//                 Tab(text: 'tab_error_boundary'.tr),
//               ],
//             ),
//           ),
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           BasicAutoTrackDemo(),
//           MapListPreciseDemo(),
//           ComputedDemo(),
//           const EventBusDemo(),
//           const PerformanceTestDemo(),
//           const PerformanceTestDemoA(),
//           const MainTabWrapper(),
//           FreatureHomePage(),
//           HomeP(),
//           PollPage(),
//           SearchPage(),
//           DioPage(),
//           AutoDisposePage(),
//           DataDispose(),
//           Showcase(),
//           ErrorBoundaryDemo(),
//         ],
//       ),
//     );
//   }
// }

// // ==================== 1. 基础自动依赖追踪 ====================
// class BasicAutoTrackDemo extends StatelessWidget {
//   BasicAutoTrackDemo({super.key});

//   final count = 0.obs;
//   final name = "张三".obs;
//   final isActive = true.obs;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Center(
//         child: Container(
//           constraints: const BoxConstraints(maxWidth: 400),
//           child: Column(
//             children: [
//               Card(
//                 elevation: 4,
//                 shadowColor: theme.colorScheme.shadow.withValues(alpha: .1),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//                 child: Padding(
//                   padding: const EdgeInsets.all(24),
//                   child: Rx(
//                     () => Column(
//                       children: [
//                         CircleAvatar(
//                           radius: 36,
//                           backgroundColor: theme.colorScheme.primaryContainer,
//                           child: Icon(Icons.person, size: 36, color: theme.colorScheme.primary),
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           'name_label'.trParams({'name': name.value}),
//                           style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'count_label'.trParams({'count': '${count.value}'}),
//                           style: theme.textTheme.displayMedium?.copyWith(
//                             color: theme.colorScheme.primary,
//                             fontWeight: FontWeight.w800,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//                           decoration: BoxDecoration(
//                             color: isActive.value ? Colors.green.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Text(
//                             'status_label'.trParams({'status': isActive.value ? 'status_active'.tr : 'status_inactive'.tr}),
//                             style: TextStyle(
//                               color: isActive.value ? Colors.green : Colors.red,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 32),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   FloatingActionButton.extended(
//                     heroTag: 'fab_add',
//                     onPressed: () => count.value++,
//                     icon: const Icon(Icons.add),
//                     label: const Text("计数"),
//                   ),
//                   FloatingActionButton.extended(
//                     heroTag: 'fab_name',
//                     onPressed: () => name.value = name.value == "张三" ? "李四" : "张三",
//                     icon: const Icon(Icons.swap_horiz),
//                     label: const Text("切人"),
//                   ),
//                   FloatingActionButton.extended(
//                     heroTag: 'fab_active',
//                     onPressed: () => isActive.value = !isActive.value,
//                     icon: const Icon(Icons.power_settings_new),
//                     label: const Text("开关"),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ==================== 2. Map/List 精准更新 ====================
// class MapListPreciseDemo extends StatelessWidget {
//   MapListPreciseDemo({super.key});

//   final user = {"name": "Tom", "age": 25, "score": 88, "vip": true}.obs;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Center(
//         child: Container(
//           constraints: const BoxConstraints(maxWidth: 420),
//           child: Card(
//             elevation: 3,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 children: [
//                   Rx(
//                     () => ListTile(
//                       contentPadding: EdgeInsets.zero,
//                       leading: CircleAvatar(
//                         backgroundColor: user.getItem('vip') ? Colors.amber : Colors.grey.shade300,
//                         child: Icon(
//                           user.getItem('vip') ? Icons.star : Icons.person,
//                           color: user.getItem('vip') ? Colors.white : Colors.grey.shade700,
//                         ),
//                       ),
//                       title: Text(
//                         'user_name'.trParams({'name': '${user.getItem('name')}'}),
//                         style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                       ),
//                       subtitle: Text(user.getItem('vip') ? 'user_vip'.tr : 'user_normal'.tr),
//                     ),
//                   ),
//                   const Divider(height: 32),
//                   Rx(
//                     () => Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         _buildStatTile(context, 'user_age'.trParams({'age': ''}), '${user.getItem('age')}', Icons.cake),
//                         _buildStatTile(context, 'user_score'.trParams({'score': ''}), '${user.getItem('score')}', Icons.score, color: Colors.orange),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 32),
//                   Wrap(
//                     spacing: 12,
//                     runSpacing: 12,
//                     alignment: WrapAlignment.center,
//                     children: [
//                       OutlinedButton.icon(
//                         onPressed: () => user.updateField("name", user.getItem("name") == "Tom" ? "Jerry" : "Tom"),
//                         icon: const Icon(Icons.edit),
//                         label: Text('btn_change_name'.tr),
//                       ),
//                       OutlinedButton.icon(
//                         onPressed: () => user.updateField("age", user.getItem("age") + 1),
//                         icon: const Icon(Icons.add),
//                         label: Text('btn_age_plus'.tr),
//                       ),
//                       OutlinedButton.icon(
//                         onPressed: () => user.updateField("score", user.getItem("score") + 10),
//                         icon: const Icon(Icons.star_rate),
//                         label: Text('btn_add_score'.tr),
//                       ),
//                       OutlinedButton.icon(
//                         onPressed: () => user.updateField("vip", !user.getItem("vip")),
//                         icon: const Icon(Icons.card_membership),
//                         label: Text('btn_toggle_vip'.tr),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStatTile(BuildContext context, String label, String value, IconData icon, {Color? color}) {
//     final theme = Theme.of(context);
//     return Column(
//       children: [
//         Icon(icon, color: color ?? theme.colorScheme.primary, size: 28),
//         const SizedBox(height: 6),
//         Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
//         Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
//       ],
//     );
//   }
// }

// // ==================== 3. Computed 计算属性 ====================
// class ComputedDemo extends StatelessWidget {
//   ComputedDemo({super.key});

//   final price = 99.obs;
//   final quantity = 1.obs;

//   late final total = computed(() => price.value * quantity.value);
//   late final isExpensive = computed(() => total.value > 500);

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Center(
//         child: Container(
//           constraints: const BoxConstraints(maxWidth: 400),
//           child: Card(
//             elevation: 3,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Rx(
//                 () => Column(
//                   children: [
//                     Text('product_title'.tr, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 24),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text('unit_price'.trParams({'price': '${price.value}'}), style: const TextStyle(fontSize: 16)),
//                         Row(
//                           children: [
//                             IconButton.filledTonal(
//                               onPressed: quantity.value > 1 ? () => quantity.value-- : null,
//                               icon: const Icon(Icons.remove),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 16),
//                               // key: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                               child: Text('${quantity.value}'),
//                             ),
//                             IconButton.filledTonal(
//                               onPressed: () => quantity.value++,
//                               icon: const Icon(Icons.add),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                     const Divider(height: 36),
//                     Text('total_price'.trParams({'total': '${total.value}'}), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
//                     const SizedBox(height: 12),
//                     AnimatedContainer(
//                       duration: const Duration(milliseconds: 300),
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: isExpensive.value ? Colors.red.shade50 : Colors.green.shade50,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         isExpensive.value ? 'high_consumption'.tr : 'good_value'.tr,
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: isExpensive.value ? Colors.red : Colors.green,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ==================== 4. RxEventBus 事件总线 ====================
// class EventBusDemo extends StatefulWidget {
//   const EventBusDemo({super.key});

//   @override
//   State<EventBusDemo> createState() => _EventBusDemoState();
// }

// class _EventBusDemoState extends State<EventBusDemo> {
//   final messages = <String>[].obs;
//   final token = EventToken();

//   @override
//   void initState() {
//     super.initState();
//     RxEventBus.on<String>(
//       module: "chat",
//       eventID: 1001,
//       token: token,
//       callback: (id, uuid, data) async {
//         messages.add('received_message'.trParams({'msg': data}));
//       },
//     );
//   }

//   @override
//   void dispose() {
//     RxEventBus.offByToken(token);
//     super.dispose();
//   }

//   void sendMessage() {
//     final text = 'message_content'.trParams({'num': '${messages.length + 1}'});
//     RxEventBus.notify<String>(module: "chat", eventID: 1001, data: text);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           Card(
//             elevation: 2,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Text('点击按钮通过 RxEventBus 发送一条消息', style: theme.textTheme.bodyMedium),
//                   ),
//                   FilledButton.icon(
//                     onPressed: sendMessage,
//                     icon: const Icon(Icons.send_rounded),
//                     label: const Text("发送"),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Expanded(
//             child: Rx(
//               () => messages.isEmpty
//                   ? Center(child: Text("暂无消息", style: TextStyle(color: Colors.grey.shade500)))
//                   : ListView.separated(
//                       itemCount: messages.length,
//                       separatorBuilder: (_, __) => const SizedBox(height: 8),
//                       itemBuilder: (context, index) => Card(
//                         elevation: 0,
//                         color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         child: ListTile(
//                           leading: CircleAvatar(
//                             backgroundColor: theme.colorScheme.primaryContainer,
//                             child: Icon(Icons.chat_bubble_outline, size: 20, color: theme.colorScheme.primary),
//                           ),
//                           title: Text(messages.value[index]),
//                         ),
//                       ),
//                     ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ==================== 5. 性能测试页 ====================
// class PerformanceTestDemoA extends StatefulWidget {
//   const PerformanceTestDemoA({super.key});

//   @override
//   State<PerformanceTestDemoA> createState() => _PerformanceTestDemoStateA();
// }

// class _PerformanceTestDemoStateA extends State<PerformanceTestDemoA> {
//   final items = List.generate(1000, (i) => {"id": i, "title": "Item $i", "score": 50 + (i % 50)}).obs;

//   final totalRebuildCount = 0.obs;
//   final updateCount = 0.obs;

//   void updateRandomItem() {
//     final randomIndex = DateTime.now().millisecond % 1000;
//     final current = items.getItem(randomIndex);
//     final newMap = <String, Object>{...current, "score": (current["score"] as int) + 10};

//     items.updateField(randomIndex, newMap);
//     updateCount.value++;
//   }

//   @override
//   Widget build(BuildContext context) {
//     totalRebuildCount.value++;
//     final theme = Theme.of(context);

//     return Column(
//       children: [
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.all(16),
//           color: theme.colorScheme.surfaceContainerLow,
//           child: Column(
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   Rx(() => _buildHeaderBadge("页面 Build", '${totalRebuildCount.value}', Colors.blue)),
//                   Rx(() => _buildHeaderBadge("数据更新", '${updateCount.value}', Colors.orange)),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               FilledButton.icon(
//                 onPressed: updateRandomItem,
//                 icon: const Icon(Icons.dynamic_feed),
//                 label: Text('random_update'.tr),
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: ListView.builder(
//             itemCount: 1000,
//             itemBuilder: (context, index) {
//               return Rx(() {
//                 final item = items.getItem(index);
//                 return ListTile(
//                   dense: true,
//                   title: Text(item["title"] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
//                   subtitle: Text('score_label'.trParams({'score': '${item["score"]}'})),
//                   trailing: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: theme.colorScheme.primaryContainer,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       "+10",
//                       style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 );
//               });
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildHeaderBadge(String label, String value, Color color) {
//     return Column(
//       children: [
//         Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
//         Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
//       ],
//     );
//   }
// }

// // ==================== 5. 性能测试页（最终推荐版）===================
// class PerformanceTestDemo extends StatefulWidget {
//   const PerformanceTestDemo({super.key});

//   @override
//   State<PerformanceTestDemo> createState() => _PerformanceTestDemoState();
// }

// class _PerformanceTestDemoState extends State<PerformanceTestDemo> {
//   final items = List.generate(1000, (i) => {"id": i, "title": "Item $i", "score": 50 + (i % 50)}).obsListMap;

//   final rebuildCount = 0.obs;
//   final updateCount = 0.obs;

//   void updateRandomItem() {
//     final randomIndex = DateTime.now().millisecond % 1000;
//     final current = items[randomIndex];

//     items.updateAt(randomIndex, {...current, "score": (current["score"] as num) + 10});
//     updateCount.value++;
//   }

//   @override
//   Widget build(BuildContext context) {
//     rebuildCount.value++;
//     final theme = Theme.of(context);

//     return Column(
//       children: [
//         Container(
//           margin: const EdgeInsets.all(16),
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: theme.colorScheme.surface,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withValues(alpha: 0.05),
//                 blurRadius: 10,
//                 offset: const Offset(0, 4),
//               )
//             ],
//           ),
//           child: Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Rx(() => Text("页面 Build: ${rebuildCount.value}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
//                     const SizedBox(height: 4),
//                     Rx(() => Text("局部更新: ${updateCount.value}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
//                   ],
//                 ),
//               ),
//               FilledButton.icon(
//                 onPressed: updateRandomItem,
//                 icon: const Icon(Icons.touch_app),
//                 label: const Text("随机更新"),
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: ListView.separated(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             itemCount: items.length,
//             separatorBuilder: (_, __) => const Divider(height: 1),
//             itemBuilder: (context, index) {
//               return Rx(() {
//                 final item = items[index];
//                 return ListTile(
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 8),
//                   title: Text(item["title"] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
//                   subtitle: Text("当前分数: ${item["score"]}"),
//                   trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
//                 );
//               });
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

import 'auto_dispose/auto_dispose.dart';
import 'auto_dispose/data_dispose.dart';
import 'error_boundary_demo.dart';
import 'feature/features/home/controller/dio_controller.dart';
import 'feature/features/home/controller/home_controller.dart';
import 'feature/features/home/controller/page_controller.dart';
import 'feature/features/home/controller/poll_controller.dart';
import 'feature/features/home/controller/search_controller.dart';

import 'router_demo.dart';
import 'showcase.dart';

final isDarkMode = true.obs; // 默认深色调更容易出惊艳感

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
    return Rx(() {
      final dark = isDarkMode.value;
      return Theme(
        data: dark
            ? ThemeData.dark(useMaterial3: true).copyWith(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF6366F1),
                  brightness: Brightness.dark,
                  surface: const Color(0xFF0F172A),
                ),
                scaffoldBackgroundColor: const Color(0xFF0B0F19),
              )
            : ThemeData.light(useMaterial3: true).copyWith(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF6366F1),
                  brightness: Brightness.light,
                  surface: const Color(0xFFF8FAFC),
                ),
                scaffoldBackgroundColor: const Color(0xFFF1F5F9),
              ),
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                title: Rx(
                  () => Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF818CF8), Color(0xFF6366F1)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'core_features_title'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.translate_rounded, size: 20),
                    ),
                    onSelected: (locale) => RxLocale.setLocale(Locale(locale)),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'zh', child: Text("中文")),
                      PopupMenuItem(value: 'en', child: Text("English")),
                      PopupMenuItem(value: 'ja', child: Text("日本語")),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12)),
                      child: Icon(dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 20),
                    ),
                    onPressed: () => isDarkMode.value = !isDarkMode.value,
                  ),
                  const SizedBox(width: 16),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
                    ),
                    child: Rx(
                      () => TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))
                          ],
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  BasicAutoTrackDemo(),
                  MapListPreciseDemo(),
                  ComputedDemo(),
                  const EventBusDemo(),
                  const PerformanceTestDemo(),
                  const PerformanceTestDemoA(),
                  const MainTabWrapper(),
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
          },
        ),
      );
    });
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
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              // 极具科技感的 Glow 渐变卡片
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surface.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: -5,
                      offset: const Offset(0, 15),
                    ),
                  ],
                  border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
                ),
                padding: const EdgeInsets.all(28),
                child: Rx(
                  () => Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)]),
                        ),
                        child: const CircleAvatar(
                          radius: 36,
                          backgroundColor: Color(0xFF0F172A),
                          child: Icon(Icons.person_rounded, size: 36, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'name_label'.trParams({'name': name.value}),
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF818CF8), Color(0xFFC084FC)],
                        ).createShader(bounds),
                        child: Text(
                          '${count.value}',
                          style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                        ),
                      ),
                      Text('count_label'.trParams({'count': ''}), style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                      const SizedBox(height: 20),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive.value ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isActive.value ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive.value ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isActive.value ? 'status_active'.tr : 'status_inactive'.tr,
                              style: TextStyle(
                                color: isActive.value ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // 霓虹感控制按钮组
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGlowButton(
                    icon: Icons.add_rounded,
                    label: "加一",
                    color: const Color(0xFF6366F1),
                    onTap: () => count.value++,
                  ),
                  _buildGlowButton(
                    icon: Icons.swap_horiz_rounded,
                    label: "切人",
                    color: const Color(0xFF8B5CF6),
                    onTap: () => name.value = name.value == "张三" ? "李四" : "张三",
                  ),
                  _buildGlowButton(
                    icon: Icons.power_settings_new_rounded,
                    label: "开关",
                    color: const Color(0xFFEC4899),
                    onTap: () => isActive.value = !isActive.value,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlowButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
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
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: .08)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                Rx(() {
                  final isVip = user.getItem('vip') as bool;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isVip
                          ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)])
                          : LinearGradient(colors: [theme.colorScheme.surfaceContainerHighest, theme.colorScheme.surfaceContainerHighest]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black26,
                          child: Icon(isVip ? Icons.workspace_premium_rounded : Icons.person_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.getItem('name')}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              isVip ? 'PREMIUM VIP MEMBER' : 'STANDARD USER',
                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8), letterSpacing: 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Rx(
                  () => Row(
                    children: [
                      Expanded(child: _buildMetricTile(context, "年龄", '${user.getItem('age')}', Icons.cake_rounded, const Color(0xFF3B82F6))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricTile(context, "积分", '${user.getItem('score')}', Icons.stars_rounded, const Color(0xFFF59E0B))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildActionButton("改名", Icons.edit_rounded, () => user.updateField("name", user.getItem("name") == "Tom" ? "Jerry" : "Tom")),
                    _buildActionButton("年龄+1", Icons.add_circle_outline_rounded, () => user.updateField("age", user.getItem("age") + 1)),
                    _buildActionButton("积分+10", Icons.star_border_rounded, () => user.updateField("score", user.getItem("score") + 10)),
                    _buildActionButton("切换VIP", Icons.card_membership_rounded, () => user.updateField("vip", !user.getItem("vip"))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
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
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
              boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.08), blurRadius: 25, offset: const Offset(0, 8))],
            ),
            child: Rx(
              () => Column(
                children: [
                  Text('product_title'.tr, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('unit_price'.trParams({'price': '￥${price.value}'}), style: const TextStyle(fontWeight: FontWeight.w600)),
                        Row(
                          children: [
                            _buildCounterBtn(Icons.remove_rounded, quantity.value > 1 ? () => quantity.value-- : null),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('${quantity.value}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                            _buildCounterBtn(Icons.add_rounded, () => quantity.value++),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('合计总价', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    '￥${total.value}',
                    style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(height: 16),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isExpensive.value ? Colors.red.withValues(alpha: 0.12) : Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isExpensive.value ? Colors.red : Colors.green),
                    ),
                    child: Text(
                      isExpensive.value ? 'high_consumption'.tr : 'good_value'.tr,
                      style: TextStyle(fontWeight: FontWeight.bold, color: isExpensive.value ? Colors.red : Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounterBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: const Color(0xFF6366F1)),
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
  final messages = <String>[].obs;
  final token = EventToken();

  @override
  void initState() {
    super.initState();
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
    RxEventBus.offByToken(token);
    super.dispose();
  }

  void sendMessage() {
    final text = 'message_content'.trParams({'num': '${messages.length + 1}'});
    RxEventBus.notify<String>(module: "chat", eventID: 1001, data: text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text("解耦通信：点击按钮广播事件，列表即时响应", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF6366F1)),
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text("发送"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Rx(
              () => ListView.separated(
                itemCount: messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      child: const Icon(Icons.mark_chat_unread_rounded, size: 20, color: Color(0xFF6366F1)),
                    ),
                    title: Text(messages.value[index], style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 5. 性能测试页 ====================
class PerformanceTestDemoA extends StatefulWidget {
  const PerformanceTestDemoA({super.key});

  @override
  State<PerformanceTestDemoA> createState() => _PerformanceTestDemoStateA();
}

class _PerformanceTestDemoStateA extends State<PerformanceTestDemoA> {
  final items = List.generate(1000, (i) => {"id": i, "title": "Item $i", "score": 50 + (i % 50)}).obs;

  final totalRebuildCount = 0.obs;
  final updateCount = 0.obs;

  void updateRandomItem() {
    final randomIndex = DateTime.now().millisecond % 1000;
    final current = items.getItem(randomIndex);
    final newMap = <String, Object>{...current, "score": (current["score"] as int) + 10};

    items.updateField(randomIndex, newMap);
    updateCount.value++;
  }

  @override
  Widget build(BuildContext context) {
    totalRebuildCount.value++;
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Rx(() => _buildStatTile("全页 Rebuild", '${totalRebuildCount.value}', Colors.blue)),
              Rx(() => _buildStatTile("局部更新次数", '${updateCount.value}', Colors.orange)),
              ElevatedButton.icon(
                onPressed: updateRandomItem,
                icon: const Icon(Icons.bolt_rounded),
                label: const Text("随机刷新"),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 1000,
            itemBuilder: (context, index) {
              return Rx(() {
                final item = items.getItem(index);
                return ListTile(
                  dense: true,
                  title: Text(item["title"] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('score_label'.trParams({'score': '${item["score"]}'})),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("+10", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ==================== 5. 性能测试页（推荐版）===================
class PerformanceTestDemo extends StatefulWidget {
  const PerformanceTestDemo({super.key});

  @override
  State<PerformanceTestDemo> createState() => _PerformanceTestDemoState();
}

class _PerformanceTestDemoState extends State<PerformanceTestDemo> {
  final items = List.generate(1000, (i) => {"id": i, "title": "Item $i", "score": 50 + (i % 50)}).obsListMap;

  final rebuildCount = 0.obs;
  final updateCount = 0.obs;

  void updateRandomItem() {
    final randomIndex = DateTime.now().millisecond % 1000;
    final current = items[randomIndex];

    items.updateAt(randomIndex, {...current, "score": (current["score"] as num) + 10});
    updateCount.value++;
  }

  @override
  Widget build(BuildContext context) {
    rebuildCount.value++;
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Rx(() => Text("全页面 Build: ${rebuildCount.value}", style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold))),
                    const SizedBox(height: 4),
                    Rx(() => Text("局部精准更新: ${updateCount.value}", style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
                onPressed: updateRandomItem,
                icon: const Icon(Icons.touch_app_rounded, size: 18),
                label: const Text("随机改值"),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return Rx(() {
                final item = items[index];
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(item["title"] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("当前分数: ${item["score"]}"),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
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