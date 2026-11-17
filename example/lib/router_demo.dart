// import 'package:material_ui/material_ui.dart';
// import 'package:rxflare/rxflare.dart';

// class MainTabWrapper extends StatefulWidget {
//   const MainTabWrapper({super.key});

//   @override
//   State<MainTabWrapper> createState() => _MainTabWrapperState();
// }

// class _MainTabWrapperState extends State<MainTabWrapper> {
//   @override
//   void initState() {
//     super.initState();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;

//       rxr.initTabIfNeeded(0, [
//         RxPage(name: "/RouterHomePage", pageId: "tab0_root"),
//       ]);

//       rxr.initTabIfNeeded(1, [
//         RxPage(name: "/HomeScreen", pageId: "tab1_root"),
//       ]);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return RxBuilder(
//       builder: (context) => Scaffold(
//         body: IndexedStack(
//           index: rxr.activeTabIndex.value,
//           children: [
//             Router(
//               routerDelegate: RxRouterDelegate(
//                 customStack: rxr.tabPages[0],
//               ),
//             ),
//             Router(
//               routerDelegate: RxRouterDelegate(
//                 customStack: rxr.tabPages[1],
//               ),
//             ),
//           ],
//         ),
//         bottomNavigationBar: BottomNavigationBar(
//           currentIndex: rxr.activeTabIndex.value,
//           onTap: rxr.switchTab,
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(Icons.home),
//               label: "Home",
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.person),
//               label: "Me",
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class RouterHomePage extends StatelessWidget {
//   const RouterHomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: () async {
//                 //  现在可以正常跳转了
//                 final result = await rxr.to(
//                   "/detail?id=123&type=vip",
//                   arguments: {"name": "ZhangSan"},
//                 );
//                 debugPrint("return: $result");
//               },
//               child: const Text("detail"),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 rxr.to("/admin");
//               },
//               child: const Text("into admin"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class DetailPage extends StatelessWidget {
//   const DetailPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     //  使用 rxflare 官方方式获取参数
//     final id = rxr.queryItem("id");
//     final type = rxr.queryItem("type");
//     final args = rxr.args();

//     return Scaffold(
//       appBar: AppBar(title: Text("详情 $id")),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             Text("ID: $id"),
//             Text("Type: $type"),
//             Text("Args: $args"),
//             const Spacer(),
//             ElevatedButton(
//               onPressed: () {
//                 rxr.back(result: "来自详情页的数据");
//               },
//               child: const Text("返回"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class LoginPage extends StatelessWidget {
//   const LoginPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("登录")),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () => rxr.back(result: "ok"),
//           child: const Text("模拟登录成功并返回"),
//         ),
//       ),
//     );
//   }
// }

// class AdminPage extends StatelessWidget {
//   const AdminPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final id = rxr.param("id");
//     final type = rxr.queryItem("type");
//     final args = rxr.args();

//     return Scaffold(
//       appBar: AppBar(title: const Text("管理页")),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             Text("路径参数 ID: $id"),
//             Text("Query 类型: $type"),
//             Text("传递的对象: $args"),
//             const Spacer(),
//             ElevatedButton(
//               onPressed: () => rxr.back(result: "我是从管理页回来的数据"),
//               child: const Text("带着结果返回"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ProfilePage extends StatelessWidget {
//   const ProfilePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // 获取当前页面的 pageId (调试用)
//     final currentId = rxr.pageId();

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("个人中心"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.settings),
//             onPressed: () {
//               // 跳转到设置页（假设你注册了 /setting）
//               rxr.to("/setting");
//             },
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             const SizedBox(height: 30),
//             const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
//             const SizedBox(height: 16),
//             const Text(
//               "Flutter 开发者",
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const Divider(height: 40),

//             // 展示当前路由信息
//             ListTile(
//               leading: const Icon(Icons.info_outline),
//               title: const Text("当前 PageID"),
//               subtitle: Text(currentId ?? "未知"),
//             ),

//             ListTile(
//               leading: const Icon(Icons.account_balance_wallet_outlined),
//               title: const Text("我的钱包"),
//               onTap: () {
//                 // 演示路径传参
//                 rxr.to("/detail/wallet?from=profile");
//               },
//             ),

//             ListTile(
//               leading: const Icon(Icons.exit_to_app, color: Colors.red),
//               title: const Text(
//                 "模拟注销 (返回根栈)",
//                 style: TextStyle(color: Colors.red),
//               ),
//               onTap: () {
//                 // 这里的注销逻辑可以根据你的业务需求实现
//                 // 例如清空 tabPages 并切回第 0 个 Tab
//                 _showLogoutDialog(context);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showLogoutDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("提示"),
//         content: const Text("确定要注销并返回登录吗？"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("取消"),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               // 跳转到登录页，逻辑可以根据 RxRouter 进一步扩展
//               rxr.to("/login");
//             },
//             child: const Text("确定"),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:material_ui/material_ui.dart';
import 'package:rxflare/rxflare.dart';

// ============================================================
// Demo 专用 RouterDelegate
// 不修改 rxflare 源码，只解决多 Navigator 共用 GlobalKey 的问题。
// ============================================================



class _DemoRouterDelegate extends RxRouterDelegate {
  _DemoRouterDelegate({
    required super.customStack,
  });

  final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;
}

class MainTabWrapper extends StatefulWidget {
  const MainTabWrapper({super.key});

  @override
  State<MainTabWrapper> createState() => _MainTabWrapperState();
}




class _MainTabWrapperState extends State<MainTabWrapper> {
  _DemoRouterDelegate? _homeDelegate;
  _DemoRouterDelegate? _profileDelegate;

  int _currentIndex = 0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    // 等当前 Flutter 构建过程结束后，再初始化路由状态。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      rxr.initTabIfNeeded(0, [
        RxPage(
          name: "/RouterHomePage",
          pageId: "tab0_root",
        ),
      ]);

      rxr.initTabIfNeeded(1, [
        RxPage(
          name: "/HomeScreen",
          pageId: "tab1_root",
        ),
      ]);

      if (!mounted) return;

      final homeDelegate = _DemoRouterDelegate(
        customStack: rxr.tabPages[0]!,
      );

      final profileDelegate = _DemoRouterDelegate(
        customStack: rxr.tabPages[1]!,
      );

      setState(() {
        _homeDelegate = homeDelegate;
        _profileDelegate = profileDelegate;
        _currentIndex = rxr.activeTabIndex.value;
        _initialized = true;
      });
    });
  }

  @override
  void dispose() {
    _homeDelegate?.dispose();
    _profileDelegate?.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (index == _currentIndex) return;

    rxr.switchTab(index);

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !_initialized
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : IndexedStack(
              index: _currentIndex,
              children: [
                Router(
                  routerDelegate: _homeDelegate!,
                ),
                Router(
                  routerDelegate: _profileDelegate!,
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _switchTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Me",
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Home Page
// ============================================================

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
                final result = await rxr.to(
                  "/detail?id=123&type=vip",
                  arguments: {"name": "ZhangSan"},
                );

                debugPrint("return: $result");
              },
              child: const Text("detail"),
            ),
            ElevatedButton(
              onPressed: () {
                rxr.to("/admin");
              },
              child: const Text("into admin"),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Detail Page
// ============================================================

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
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

// ============================================================
// Login Page
// ============================================================

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

// ============================================================
// Admin Page
// ============================================================

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

// ============================================================
// Profile Page
// ============================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentId = rxr.pageId();

    return Scaffold(
      appBar: AppBar(
        title: const Text("个人中心"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
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
            const Text(
              "Flutter 开发者",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 40),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text("当前 PageID"),
              subtitle: Text(currentId ?? "未知"),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text("我的钱包"),
              onTap: () {
                rxr.to("/detail/wallet?from=profile");
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text(
                "模拟注销 (返回根栈)",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              rxr.to("/login");
            },
            child: const Text("确定"),
          ),
        ],
      ),
    );
  }
}
