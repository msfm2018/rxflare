import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
// 首页内容
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => rxr.to("/detail/123"), // 在当前 Tab 栈内跳转
          child: const Text("去详情页"),
        ),
      ),
    );
  }
}

// 详情页
class DetailPage extends StatelessWidget {
  const DetailPage({super.key});
  @override
  Widget build(BuildContext context) {
    final id = rxr.param("id");
    return Scaffold(
      appBar: AppBar(title: Text("详情 $id")),
      body: Center(child: Text("参数: $id")),
    );
  }
}