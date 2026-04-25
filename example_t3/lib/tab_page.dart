import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

class TabPage extends StatelessWidget {
  const TabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tab Page")),
      body: Column(
        children: [

          ElevatedButton(
            onPressed: () {
              RxRouter.I.to("/detail", arguments: "Tab A");
            },
            child: const Text("Tab 内跳 Detail"),
          ),

          ElevatedButton(
            onPressed: () {
              RxRouter.I.switchTab(0);
            },
            child: const Text("切回 Tab 0"),
          ),
        ],
      ),
    );
  }
}