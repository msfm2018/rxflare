import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

// ==================== 错误安全的 Computed ====================
// ==================== 错误安全的 Computed (推荐写法) ====================
class SafeComputed<T> {
  late final RxState<T?> valueRx;
  late final RxState<String?> errorRx;

  T? _lastValue;

  SafeComputed(T Function() computedFn) {
    errorRx = RxState<String?>(null);

    valueRx = computed<T?>(() {
      try {
        final result = computedFn();

        _lastValue = result;

        if (errorRx.value != null) {
          errorRx.value = null;
        }

        return result;
      } catch (e, stack) {
        final errStr = e.toString();

        if (errorRx.value != errStr) {
          errorRx.value = errStr;
        }

        debugPrint('SafeComputed error: $e\n$stack');

        return _lastValue; // ✅ 不再依赖自己
      }
    });
  }

  T? get value => valueRx.value;
  String? get error => errorRx.value;

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
  final divisor = 2.obs; // 改成 0 会触发除零错误

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
                ElevatedButton(onPressed: () => number.value++, child: const Text('+ 被除数')),
                const SizedBox(width: 20),
                Rx(() => Text('${number.value}', style: TextStyle(fontSize: 24))),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: () => divisor.value--, child: const Text('- 除数')),
                const SizedBox(width: 20),
                // Text('${divisor.value}', style: const TextStyle(fontSize: 24)),
                Rx(() => Text('${divisor.value}', style: TextStyle(fontSize: 24))),
                const SizedBox(width: 20),
                ElevatedButton(onPressed: () => divisor.value++, child: const Text('+ 除数')),
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

              return Text('计算结果: ${safeResult.value}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
            }),
          ],
        ),
      ),
    );
  }
}
