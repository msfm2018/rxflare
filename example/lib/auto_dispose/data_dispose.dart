import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
// 2. RxProvider + Controller（中大型项目推荐架构）
// 特点：采用 Controller 模式，业务逻辑与 UI 分离，RxProvider 自动管理 Controller 的生命周期。
// 适用场景：

// 中大型项目
// 需要多人协作
// 业务逻辑复杂
// Controller 需要复用
// 严格分层架构
// 优点：

// 逻辑与 UI 完全分离
// Controller 可复用、可测试
// RxProvider 自动调用 dispose()
// 适合团队协作和大型项目
class User {
  final String? name;

  User({this.name});
}

/// ====================== Controller ======================
class UserController implements Disposable {
  final count = 0.obs;
  late final RxFuture<User> userFuture;

  UserController() {
    userFuture = RxFuture((cancelToken) async {
      await Future.delayed(const Duration(seconds: 1));
      return User(name: "张三");
    });
  }

  void increment() => count.value++;

  // 会被自动调用
  @override
  void dispose() {
    userFuture.dispose();
    count.dispose();
    print("UserController 已释放");
  }
}

/// ====================== Page ======================
class DataDispose extends StatelessWidget {
  const DataDispose({super.key});

  @override
  Widget build(BuildContext context) {
    // RxProvider 自动调用 dispose()
    return RxProvider<UserController>(
      dependency: UserController(), // 自动注入
      name: "data_dispose", // 可选：多实例隔离
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
  late final UserController controller;

  @override
  void initState() {
    super.initState();
    controller = RxDI.find<UserController>(name: "data_dispose");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Rx(
          () => SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// 标题
                const Text('2. RxProvider + Controller', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

                const SizedBox(height: 12),

                /// 描述卡片
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('''
RxProvider 是 RxFlare 官方推荐的页面级依赖注入与生命周期管理容器。

配合 Controller 模式使用，
可以实现业务逻辑与 UI 完全分离。

核心优势：

• 清晰分层（Controller + View）
• Controller 可复用、可测试
• 自动管理 dispose 生命周期
• 支持多实例隔离

适用场景：

• 中大型项目
• 团队协作
• 复杂业务
• 长期维护项目
''', style: const TextStyle(fontSize: 14, height: 1.7)),
                  ),
                ),

                const SizedBox(height: 32),

                Center(child: Rx(() => Text('计数: ${controller.count.value}', style: const TextStyle(fontSize: 48)))),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: controller.increment, child: const Icon(Icons.add)),
    );
  }
}
