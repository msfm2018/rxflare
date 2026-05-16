import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'RxFlare 错误边界 Demo',
//       home: const ErrorBoundaryDemo(),
//     );
//   }
// }

// ==================== 错误安全的 Computed ====================
// ==================== 错误安全的 Computed (推荐写法) ====================
class SafeComputed<T> {
  late final RxState<T?> valueRx;   // 使用 RxState
  late final RxState<String?> errorRx;

  SafeComputed(T Function() computedFn) {
    // 错误状态
    errorRx = RxState<String?>(null);

    // 安全的 computed
    valueRx = computed(() {
      try {
        final result = computedFn();
        errorRx.value = null;           // 清除之前的错误
        return result;
      } catch (e, stack) {
        errorRx.value = e.toString();
        debugPrint('SafeComputed 内部异常: $e\n$stack');
        
        // 返回上一次成功的值，防止崩溃
        return valueRx.value;
      }
    }) as RxState<T?>;   // computed 返回的结果转为 RxState
  }

  T? get value => valueRx.value;
  String? get error => errorRx.value;

  // 方便在 Rx() 中使用
  RxState<T?> get rxValue => valueRx;
  RxState<String?> get rxError => errorRx;
}

// ==================== Demo Page ====================
class ErrorBoundaryDemo extends StatefulWidget {
  const ErrorBoundaryDemo({super.key});

  @override
  State<ErrorBoundaryDemo> createState() => _ErrorBoundaryDemoState();
}

class _ErrorBoundaryDemoState extends State<ErrorBoundaryDemo> {
  final number = 10.obs;
  final divisor = 2.obs;   // 改成 0 会触发除零错误

  // 使用 SafeComputed 包装可能出错的计算
  late final SafeComputed<int> safeResult;

  @override
  void initState() {
    super.initState();
    
    safeResult = SafeComputed(() {
      if (divisor.value == 0) {
        throw Exception("除数不能为 0！（模拟计算错误）");
      }
      return number.value ~/ divisor.value; // 整数除法
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RxFlare 错误边界演示')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('修改除数为 0 观察效果', style: TextStyle(fontSize: 18)),

            const SizedBox(height: 30),

            // 正常输入区域
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => number.value++,
                  child: const Text('+ 被除数'),
                ),
                const SizedBox(width: 20),
                Text('${number.value}', style: const TextStyle(fontSize: 24)),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => divisor.value--,
                  child: const Text('- 除数'),
                ),
                const SizedBox(width: 20),
                Text('${divisor.value}', style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => divisor.value++,
                  child: const Text('+ 除数'),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // === 安全的 Computed 显示 ===
            Rx(() {
              final err = safeResult.error;
              if (err != null) {
                return Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 8),
                        Text('计算出错', style: TextStyle(color: Colors.red.shade700, fontSize: 18)),
                        Text(err, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text('但程序未崩溃，继续可正常操作', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }

              return Text(
                '计算结果: ${safeResult.value}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              );
            }),
          ],
        ),
      ),
    );
  }
}