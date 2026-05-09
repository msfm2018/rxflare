import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

import 'app_routes.dart';

class RouterDemo extends StatelessWidget {
  const RouterDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. 注册路由（这里一定要正确）
    rxr.register(AppRoutes.routes);

    // 2. 必须用 Router + Delegate，不能用 Navigator！
    return Router(
      routerDelegate: RxRouterDelegate(), // 核心
      routeInformationParser: RxRouteParser(), // 核心
    );
  }
}

class MainTabWrapper extends StatefulWidget {
  const MainTabWrapper({super.key});

  @override
  State<MainTabWrapper> createState() => _MainTabWrapperState();
}

class _MainTabWrapperState extends State<MainTabWrapper> {
  @override
  void initState() {
    super.initState();
    rxr.initTabIfNeeded(0, [RxPage(name: "/RouterHomePage", pageId: "tab0_root")]);

    rxr.initTabIfNeeded(1, [RxPage(name: "/HomeScreen", pageId: "tab1_root")]);
  }

  @override
  Widget build(BuildContext context) {
    // 使用 RxBuilder 监听变化
    return RxBuilder(
      builder: (context) => Scaffold(
        body: IndexedStack(
          index: rxr.activeTabIndex.value, // 假设这里已变为响应式
          children: [
            Router(routerDelegate: RxRouterDelegate(customStack: rxr.tabPages[0])),
            Router(routerDelegate: RxRouterDelegate(customStack: rxr.tabPages[1])),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: rxr.activeTabIndex.value,
          onTap: (index) => rxr.switchTab(index), // 内部修改 RxState 即可
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "首页"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "我的"),
          ],
        ),
      ),
    );
  }
}

class RouterHomePage extends StatelessWidget {
  const RouterHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                // ✅ 现在可以正常跳转了
                final result = await rxr.to("/detail?id=123&type=vip", arguments: {"name": "张三"});
                debugPrint("收到详情页返回: $result");
              },
              child: const Text("跳转详情"),
            ),
            ElevatedButton(
              onPressed: () {
                rxr.to("/admin");
              },
              child: const Text("进入管理页"),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ 使用 rxflare 官方方式获取参数
    final id = rxr.queryItem("id");
    final type = rxr.queryItem("type");
    final args = rxr.args();

    return Scaffold(
      appBar: AppBar(title: Text("详情 $id")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("ID: $id"),
            Text("Type: $type"),
            Text("Args: $args"),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                rxr.back(result: "来自详情页的数据");
              },
              child: const Text("返回"),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("登录")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => rxr.back(result: "ok"),
          child: const Text("模拟登录成功并返回"),
        ),
      ),
    );
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final id = rxr.param("id");
    final type = rxr.queryItem("type");
    final args = rxr.args();

    return Scaffold(
      appBar: AppBar(title: const Text("管理页")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("路径参数 ID: $id"),
            Text("Query 类型: $type"),
            Text("传递的对象: $args"),
            const Spacer(),
            ElevatedButton(
              onPressed: () => rxr.back(result: "我是从管理页回来的数据"),
              child: const Text("带着结果返回"),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取当前页面的 pageId (调试用)
    final currentId = rxr.pageId();

    return Scaffold(
      appBar: AppBar(
        title: const Text("个人中心"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 跳转到设置页（假设你注册了 /setting）
              rxr.to("/setting");
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 16),
            const Text("Flutter 开发者", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(height: 40),

            // 展示当前路由信息
            ListTile(leading: const Icon(Icons.info_outline), title: const Text("当前 PageID"), subtitle: Text(currentId ?? "未知")),

            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text("我的钱包"),
              onTap: () {
                // 演示路径传参
                rxr.to("/detail/wallet?from=profile");
              },
            ),

            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text("模拟注销 (返回根栈)", style: TextStyle(color: Colors.red)),
              onTap: () {
                // 这里的注销逻辑可以根据你的业务需求实现
                // 例如清空 tabPages 并切回第 0 个 Tab
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("提示"),
        content: const Text("确定要注销并返回登录吗？"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 跳转到登录页，逻辑可以根据 RxRouter 进一步扩展
              rxr.to("/login");
            },
            child: const Text("确定"),
          ),
        ],
      ),
    );
  }
}
