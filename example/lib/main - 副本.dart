import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RxFlare Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home:  RxFlareDemo(),
    );
  }
}

class RxFlareDemo extends StatelessWidget {
  // 定义响应式变量（.obs 扩展）
  final count = 0.obs;
  final name = "张三".obs;
  final age = 25.obs;
  final isDarkMode = false.obs;

  RxFlareDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RxFlare 演示'),
        actions: [
          // 切换主题示例
          Rx(() => IconButton(
                icon: Icon(isDarkMode.value ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => isDarkMode.value = !isDarkMode.value,
              )),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 一个 Rx 同时监听多个变量
            Rx(() {
              print('🔄 UI 重绘了！'); // 观察控制台，可看到精准更新
              return Card(
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Hello, ${name.value}',
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '年龄: ${age.value} 岁',
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '计数: ${count.value}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 40),

            // 独立 Rx（只会响应自己的变化）
            Rx(() => Text(
                  '当前计数: ${count.value}',
                  style: const TextStyle(fontSize: 20, color: Colors.blue),
                )),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => count.value++,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'name',
            onPressed: () => name.value = name.value == "张三" ? "李四" : "张三",
            child: const Icon(Icons.person),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'age',
            onPressed: () => age.value++,
            child: const Icon(Icons.cake),
          ),
        ],
      ),
    );
  }
}