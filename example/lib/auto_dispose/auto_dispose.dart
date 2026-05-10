import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
// 1. RxAutoDispose（适用于中小型页面 / 单个文件）
// 特点：简单直接，在 StatefulWidget 中通过 mixin 自动管理资源。
// 适用场景：

// 简单页面、详情页、表单页
// 快速开发、原型验证
// 单个文件内完成所有逻辑
// 不需要复杂业务分层
// 优点：代码集中、学习成本低、上手快
// 缺点：业务逻辑和 UI 混在一起，不利于大型项目维护
class AutoDisposePage extends StatefulWidget {
  const AutoDisposePage({super.key});

  @override
  State<AutoDisposePage> createState() => _CounterPageState();
}

class _CounterPageState extends State<AutoDisposePage> with RxAutoDispose {
  final count = 0.obs;
  late final RxFuture<String> dataFuture;
  late final EventToken chatToken;

  @override
  void initState() {
    super.initState();

    // 1. RxFuture - 链式调用
    dataFuture = RxFuture((cancelToken) async {
      await Future.delayed(const Duration(seconds: 2));
      return "数据加载完成";
    }).autoDispose(this);

    // 2. EventToken - 链式调用
    chatToken = EventToken().autoDispose(this);

    RxEventBus.on<String>(module: "chat", eventID: 1001, token: chatToken, callback: (id, uuid, data) async => print("收到: $data"));

    // 3. listen() - 链式调用（最舒服的写法）
    count.listen((v) => print("数据更新: $v")).autoDispose(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// 标题
            const Text('生命周期管理：RxAutoDispose 与 RxParent ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('1. RxAutoDispose', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),

            /// 描述卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('''
              RxAutoDispose 是一个 Mixin，
              通过 with 方式混入 StatefulWidget，
              实现资源自动注册与释放。

              适用场景：
              • 简单页面
              • 表单页
              • 原型开发
              • 中小型业务模块
''', style: const TextStyle(fontSize: 14, height: 1.7)),
              ),
            ),

            const SizedBox(height: 32),

            Rx(() => Text('计数: ${count.value}', style: const TextStyle(fontSize: 48))),
            Rx(() {
              if (dataFuture.isLoading) return const CircularProgressIndicator();
              return Text(dataFuture.data ?? '');
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => count.value++, child: const Icon(Icons.add)),
    );
  }
}
