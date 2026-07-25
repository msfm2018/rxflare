// ==================== UI ====================

import 'package:flutter/material.dart';
import 'package:layerx/layerx.dart';
import 'package:rxflare/rxflare.dart';

class NotePage extends StatefulWidget {
  const NotePage({super.key});
  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('router demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('当前数值：', style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                // 简单提示对话框
                await LayerX.show('这是 LayerX 对话框提示');

                // 或者确认框（返回 true / false）
                // final ok = await LayerX.confirm('确定要执行吗？');
                // if (ok == true) {
                //   LayerX.toast('已确认');
                // }
              },
              child: const Text('弹出 LayerX 对话框'),
            ),
            ElevatedButton(
              onPressed: () async {
                // rxr.to('/detail/123?type=hot', arguments: MyData());
                //more https://github.com/msfm2018/rxflare
              },
              child: const Text('弹出 LayerX 对话框'),
            ),
          ],
        ),
      ),
    );
  }
}
