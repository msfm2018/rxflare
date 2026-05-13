import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

class DevTool extends StatefulWidget {
  const DevTool({super.key});

  @override
  State<DevTool> createState() => _DevToolState();
}

class _DevToolState extends State<DevTool> {
  // 活跃的 RxState
  final counter = RxState<int>(0, name: "Counter");
  final userInfo = RxState<Map<String, dynamic>>({"name": "张三", "age": 25, "active": true}, name: "UserInfo");

  final todoList = RxState<List<String>>(["学习 Flutter", "测试 RxFlare"], name: "TodoList");

  // 用于演示销毁的临时状态
  RxState<String>? tempState;

  @override
  void initState() {
    super.initState();
    RxObjMgr.initDevTools();//notice : add
    print("✅ HomePage 初始化完成，RxState 已注册");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RxFlare DevTools 示例'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新 DevTools',
            onPressed: () {
              RxObjMgr.clearDebugData();
              setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection("计数器", counter, () => counter.value++),
            const SizedBox(height: 16),
            _buildSection("用户信息", userInfo, () {
              userInfo.updateField('age', (userInfo.getItem('age') ?? 0) + 1);
            }),
            const SizedBox(height: 16),
            _buildSection("待办列表", todoList, () {
              final list = List<String>.from(todoList.value);
              list.add("新任务 ${list.length + 1}");
              todoList.value = list;
            }),

            const SizedBox(height: 30),
            const Text("销毁演示", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () {
                tempState = RxState<String>("临时数据", name: "TempState");
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已创建临时 RxState')));
              },
              child: const Text("创建临时 RxState"),
            ),

            if (tempState != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  RxObjMgr.unregisterRx(tempState);
                  tempState?.dispose();
                  tempState = null;
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('临时 RxState 已销毁')));
                },
                child: const Text("销毁临时 RxState"),
              ),
            ],

            const SizedBox(height: 40),
            const Center(
              child: Text(
                "👉 打开 Flutter DevTools → 点击左侧 “rxflare” 查看效果",
                style: TextStyle(color: Colors.green, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection<T>(String title, RxState<T> rx, VoidCallback onUpdate) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("当前值: ${rx.value}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onUpdate, child: const Text("更新数据")),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    counter.dispose();
    userInfo.dispose();
    todoList.dispose();
    tempState?.dispose();
    super.dispose();
  }
}
