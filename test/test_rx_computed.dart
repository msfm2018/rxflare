import '../lib/rxflare.dart';

void main() {
  // 1. 定义源头 (A)
  final a = 10.obs;

  // 2. 第一层计算 (B): B = A + 5
  final b = computed(() {
    RxDebug.log("⚙️ 计算 B (依赖 A=${a.value})");
    return a.value + 5;
  });

  // 3. 第二层计算 (C): C = B * 2
  final c = computed(() {
    RxDebug.log("⚙️ 计算 C (依赖 B=${b.value})");
    return b.value * 2;
  });

  print("--- 初始状态 ---");
  print("A: ${a.value}, B: ${b.value}, C: ${c.value}"); 
  // 预期: A=10, B=15, C=30

  print("\n--- 修改 A 的值 ---");
  a.value = 20; 

  print("--- 最终状态 ---");
  print("A: ${a.value}, B: ${b.value}, C: ${c.value}");
  // 预期: A=20, B=25, C=50
}