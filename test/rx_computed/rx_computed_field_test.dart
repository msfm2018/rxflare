import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare/rxflare.dart';

void main() {
  group('RxComputed Field Reactivity', () {
    test('只依赖 Index 0 时，修改 Index 1 不应该重新计算', () {
      final list = RxList<int>([10, 20, 30]);

      var computeCount = 0;

      final result = computed(() {
        computeCount++;
        return list[0] * 2;
      });

      // 排除初始化时的计算次数
      computeCount = 0;

      list[1] = 200;

      expect(result.value, 20);
      expect(computeCount, 0);

      result.dispose();
    });

    test('只依赖 Index 0 时，修改 Index 0 应该重新计算', () {
      final list = RxList<int>([10, 20, 30]);

      var computeCount = 0;

      final result = computed(() {
        computeCount++;
        return list[0] * 2;
      });

      computeCount = 0;

      list[0] = 100;

      expect(result.value, 200);
      expect(computeCount, 1);

      result.dispose();
    });

    test('两个 Index 应该独立触发计算', () {
      final list = RxList<int>([10, 20, 30]);

      var computeCount = 0;

      final result = computed(() {
        computeCount++;
        return list[0] + list[1];
      });

      computeCount = 0;

      list[0] = 100;

      expect(result.value, 120);
      expect(computeCount, 1);

      list[1] = 200;

      expect(result.value, 300);
      expect(computeCount, 2);

      result.dispose();
    });

    test('相同值不应该触发重新计算', () {
      final list = RxList<int>([10, 20, 30]);

      var computeCount = 0;

      final result = computed(() {
        computeCount++;
        return list[0];
      });

      computeCount = 0;

      list[0] = 10;

      expect(computeCount, 0);
      expect(result.value, 10);

      result.dispose();
    });

    test('dispose 后不应该继续响应依赖变化', () {
      final list = RxList<int>([10, 20, 30]);

      var computeCount = 0;

      final result = computed(() {
        computeCount++;
        return list[0];
      });

      computeCount = 0;

      result.dispose();

      list[0] = 100;

      expect(computeCount, 0);

      // 已 dispose 的对象不再自动更新
      expect(result.value, 10);
    });
  });
}