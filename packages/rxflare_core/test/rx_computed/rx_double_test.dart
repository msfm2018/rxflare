import 'package:rxflare_core/rxflare_core.dart';

void main() {
  int computeCount = 0;

  final count = RxState<int>(10);

  final doubled = RxComputed<int>(() {
    computeCount++;
    // ignore: avoid_print
    print('compute 执行次数：$computeCount');

    return count.value * 2;
  });

  // ignore: avoid_print
  print('初始化执行次数：$computeCount');
  // ignore: avoid_print
  print('当前计算结果：${doubled.value}');

  count.value = 20;
  // ignore: avoid_print
  print('修改依赖后执行次数：$computeCount');
  // ignore: avoid_print
  print('修改后的计算结果：${doubled.value}');

  doubled.dispose();
  count.dispose();
}
