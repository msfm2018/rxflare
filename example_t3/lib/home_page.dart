import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: ListView(
        children: [

          /// ======================
          /// 基础跳转
          /// ======================
          ElevatedButton(
            onPressed: () {
              RxRouter.I.to("/detail", arguments: "Hello Detail");
            },
            child: const Text("1. 普通跳转 + 参数"),
          ),

          /// ======================
          /// await 返回值
          /// ======================
          ElevatedButton(
            onPressed: () async {
              final result = await RxRouter.I.to<String>(
                "/detail?id=123",
                arguments: "Await Test",
              );

              debugPrint("返回值: $result");
            },
            child: const Text("2. await 返回值"),
          ),

          /// ======================
          /// guard 测试
          /// ======================
          ElevatedButton(
            onPressed: () {
              RxRouter.I.to("/login");
            },
            child: const Text("3. 中间件 guard"),
          ),

          /// ======================
          /// Tab
          /// ======================
          ElevatedButton(
            onPressed: () {
              RxRouter.I.switchTab(0);
              RxRouter.I.to("/tab");
            },
            child: const Text("4. Tab 页面"),
          ),
        ],
      ),
    );
  }
}