import 'dart:ui';
import 'package:material_ui/material_ui.dart';

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

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          'core_features_title'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis, // ← 超出显示省略号
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                actions: [
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        dark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        size: 20,
                      ),
                    ),
                    onPressed: () => isDarkMode.value = !isDarkMode.value,
                  ),
                  const SizedBox(width: 16),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.08,
                        ),
                      ),
                    ),
                    child: Rx(
                      () => TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
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
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                padding: const EdgeInsets.all(28),
                child: Rx(
                  () => Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                          ),
                        ),
                        child: const CircleAvatar(
                          radius: 36,
                          backgroundColor: Color(0xFF0F172A),
                          child: Icon(
                            Icons.person_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'name_label'.trParams({'name': name.value}),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF818CF8), Color(0xFFC084FC)],
                        ).createShader(bounds),
                        child: Text(
                          '${count.value}',
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
                      Text(
                        'count_label'.trParams({'count': ''}),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isActive.value
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isActive.value
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
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
                                color: isActive.value
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isActive.value
                                  ? 'status_active'.tr
                                  : 'status_inactive'.tr,
                              style: TextStyle(
                                color: isActive.value
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
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

  Widget _buildGlowButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
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
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: .08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Rx(() {
                  final isVip = user.getItem('vip') as bool;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isVip
                          ? const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            )
                          : LinearGradient(
                              colors: [
                                theme.colorScheme.surfaceContainerHighest,
                                theme.colorScheme.surfaceContainerHighest,
                              ],
                            ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black26,
                          child: Icon(
                            isVip
                                ? Icons.workspace_premium_rounded
                                : Icons.person_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.getItem('name')}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              isVip ? 'PREMIUM VIP MEMBER' : 'STANDARD USER',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.8),
                                letterSpacing: 1,
                              ),
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
                      Expanded(
                        child: _buildMetricTile(
                          context,
                          "年龄",
                          '${user.getItem('age')}',
                          Icons.cake_rounded,
                          const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          context,
                          "积分",
                          '${user.getItem('score')}',
                          Icons.stars_rounded,
                          const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildActionButton(
                      "改名",
                      Icons.edit_rounded,
                      () => user.updateField(
                        "name",
                        user.getItem("name") == "Tom" ? "Jerry" : "Tom",
                      ),
                    ),
                    _buildActionButton(
                      "年龄+1",
                      Icons.add_circle_outline_rounded,
                      () => user.updateField("age", user.getItem("age") + 1),
                    ),
                    _buildActionButton(
                      "积分+10",
                      Icons.star_border_rounded,
                      () =>
                          user.updateField("score", user.getItem("score") + 10),
                    ),
                    _buildActionButton(
                      "切换VIP",
                      Icons.card_membership_rounded,
                      () => user.updateField("vip", !user.getItem("vip")),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
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
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Rx(
              () => Column(
                children: [
                  Text(
                    'product_title'.tr,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'unit_price'.trParams({'price': '￥${price.value}'}),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            _buildCounterBtn(
                              Icons.remove_rounded,
                              quantity.value > 1
                                  ? () => quantity.value--
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                '${quantity.value}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildCounterBtn(
                              Icons.add_rounded,
                              () => quantity.value++,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '合计总价',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '￥${total.value}',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isExpensive.value
                          ? Colors.red.withValues(alpha: 0.12)
                          : Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isExpensive.value ? Colors.red : Colors.green,
                      ),
                    ),
                    child: Text(
                      isExpensive.value
                          ? 'high_consumption'.tr
                          : 'good_value'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isExpensive.value ? Colors.red : Colors.green,
                      ),
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
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
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
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "解耦通信：点击按钮广播事件，列表即时响应",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6366F1),
                  ),
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
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.06,
                      ),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(
                        0xFF6366F1,
                      ).withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.mark_chat_unread_rounded,
                        size: 20,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    title: Text(
                      messages.value[index],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
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
  final items = List.generate(
    1000,
    (i) => {"id": i, "title": "Item $i", "score": 50 + (i % 50)},
  ).obs;

  final totalRebuildCount = 0.obs;
  final updateCount = 0.obs;

  void updateRandomItem() {
    final randomIndex = DateTime.now().millisecond % 1000;
    final current = items.getItem(randomIndex);
    final newMap = <String, Object>{
      ...current,
      "score": (current["score"] as int) + 10,
    };

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
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Rx(
                () => _buildStatTile(
                  "全页 Rebuild",
                  '${totalRebuildCount.value}',
                  Colors.blue,
                ),
              ),
              Rx(
                () => _buildStatTile(
                  "局部更新次数",
                  '${updateCount.value}',
                  Colors.orange,
                ),
              ),
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
                  title: Text(
                    item["title"] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'score_label'.trParams({'score': '${item["score"]}'}),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "+10",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
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
  final items = List.generate(
    1000,
    (i) => {"id": i, "title": "Item $i", "score": 50 + (i % 50)},
  ).obsListMap;

  final rebuildCount = 0.obs;
  final updateCount = 0.obs;

  void updateRandomItem() {
    final randomIndex = DateTime.now().millisecond % 1000;
    final current = items[randomIndex];

    items.updateAt(randomIndex, {
      ...current,
      "score": (current["score"] as num) + 10,
    });
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
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Rx(
                      () => Text(
                        "全页面 Build: ${rebuildCount.value}",
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Rx(
                      () => Text(
                        "局部精准更新: ${updateCount.value}",
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
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
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.05,
                      ),
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      item["title"] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text("当前分数: ${item["score"]}"),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
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
