import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

// --- 模拟页面 A: 首页 ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("主页")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                // 跳转详情页，传递自定义对象，并等待返回结果
                final result = await rxr.to("/detail/123?type=vip", arguments: {"name": "张三"});
                debugPrint("收到详情页返回: $result");
              },
              child: const Text("跳转详情 (ID: 123)"),
            ),
            ElevatedButton(onPressed: () => rxr.to("/admin"), child: const Text("进入管理页 (需守卫)")),
          ],
        ),
      ),
    );
  }
}

// --- 模拟页面 B: 详情页 ---
class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取路径参数 :id
    final id = rxr.param("id");
    // 获取 Query 参数 ?type=...
    final type = rxr.queryItem("type");
    // 获取 Arguments 对象
    final args = rxr.args<Map>();

    return Scaffold(
      appBar: AppBar(title: Text("详情 $id")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("路径参数 ID: $id"),
            Text("Query 类型: $type"),
            Text("传递的对象: $args"),
            const Spacer(),
            ElevatedButton(
              onPressed: () => rxr.back(result: "我是从详情页回来的数据"),
              child: const Text("带着结果返回"),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 模拟页面 C: 登录页 ---
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("登录")),
      body: Center(
        child: ElevatedButton(onPressed: () => rxr.back(), child: const Text("模拟登录成功并返回")),
      ),
    );
  }
}
