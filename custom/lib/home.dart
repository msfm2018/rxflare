import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
import 'package:simple_tree/simple_tree.dart';
import 'tree_config/menu_data.dart';

final currentTime = RxNotifier(DateTime.now());

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> scaffoldStateKey = GlobalKey<ScaffoldState>();
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    Core.instance.initPages(myAppPages); // 初始化页面配置
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      currentTime.value = DateTime.now();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 停止计时器以释放资源
    super.dispose();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // key: scaffoldStateKey,
      appBar: AppBar(
        actions: [
          Rx(() => Text(_formatTime(currentTime.value), style: const TextStyle(fontSize: 24))),
          SizedBox(width: 100),
          Padding(padding: EdgeInsets.only(right: 16.0), child: Row(children: [Text("王军"), Icon(Icons.account_circle)])),
        ],
        backgroundColor: Colors.teal,
        title: const Text('洗衣科技业务管理平台', style: TextStyle(color: Colors.white)),
      ),
      body: TreeWidget(data: data),
    );
  }
}
