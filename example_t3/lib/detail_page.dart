import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = RxRouter.I.args<String>();
    final query = RxRouter.I.query();

    return Scaffold(
      appBar: AppBar(title: const Text("Detail")),
      body: Column(
        children: [

          Text("参数: $args"),
          Text("query: $query"),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              RxRouter.I.back(result: "我是返回值 ✔");
            },
            child: const Text("返回 + result"),
          ),
        ],
      ),
    );
  }
}