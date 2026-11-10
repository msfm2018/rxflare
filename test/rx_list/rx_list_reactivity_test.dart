import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare/rxflare.dart';

void main() {
  group('RxList Fine-Grained Reactivity', () {
    test('修改 Index 1 只通知 Index 1 监听器', () {
      final list = RxList<int>([10, 20, 30]);

      var index0Count = 0;
      var index1Count = 0;
      var index2Count = 0;

      final cancel0 = list.listenByKey(0, (_) {
        index0Count++;
      });

      final cancel1 = list.listenByKey(1, (_) {
        index1Count++;
      });

      final cancel2 = list.listenByKey(2, (_) {
        index2Count++;
      });

      // 排除初始化通知
      index0Count = 0;
      index1Count = 0;
      index2Count = 0;

      list[1] = 200;

      expect(index0Count, 0);
      expect(index1Count, 1);
      expect(index2Count, 0);

      expect(list.value, [10, 200, 30]);

      cancel0();
      cancel1();
      cancel2();
      list.dispose();
    });

    test('赋值相同值不应该触发任何 Index 通知', () {
      final list = RxList<int>([10, 20, 30]);

      var notifyCount = 0;

      final cancel = list.listenByKey(1, (_) {
        notifyCount++;
      });

      notifyCount = 0;

      list[1] = 20;

      expect(notifyCount, 0);

      cancel();
      list.dispose();
    });

    test('修改 Index 不应该触发全局监听器', () {
      final list = RxList<int>([10, 20, 30]);

      var globalCount = 0;
      var fieldCount = 0;

      final cancelGlobal = list.listen((_) {
        globalCount++;
      });

      final cancelField = list.listenByKey(1, (_) {
        fieldCount++;
      });

      globalCount = 0;
      fieldCount = 0;

      list[1] = 200;

      expect(fieldCount, 1);
      expect(globalCount, 0);

      cancelGlobal();
      cancelField();
      list.dispose();
    });

    test('整体 value 更新应该触发全局监听器', () {
      final list = RxList<int>([10, 20, 30]);

      var globalCount = 0;

      final cancel = list.listen((_) {
        globalCount++;
      });

      globalCount = 0;

      list.value = [100, 200, 300];

      expect(globalCount, 1);
      expect(list.value, [100, 200, 300]);

      cancel();
      list.dispose();
    });

    test('整体 value 更新不应该触发 Index 监听器', () {
      final list = RxList<int>([10, 20, 30]);

      var fieldCount = 0;

      final cancel = list.listenByKey(1, (_) {
        fieldCount++;
      });

      fieldCount = 0;

      list.value = [100, 200, 300];

      expect(fieldCount, 0);

      cancel();
      list.dispose();
    });

    test('取消 Index 监听后不应该继续收到通知', () {
      final list = RxList<int>([10, 20, 30]);

      var notifyCount = 0;

      final cancel = list.listenByKey(1, (_) {
        notifyCount++;
      });

      notifyCount = 0;

      cancel();

      list[1] = 200;

      expect(notifyCount, 0);

      list.dispose();
    });

    test('多个 Index 监听器应该独立工作', () {
      final list = RxList<int>([10, 20, 30]);

      final counts = [0, 0, 0];

      final cancels = List.generate(3, (index) {
        return list.listenByKey(index, (_) {
          counts[index]++;
        });
      });

      counts.fillRange(0, 3, 0);

      list[0] = 100;
      list[2] = 300;

      expect(counts, [1, 0, 1]);

      for (final cancel in cancels) {
        cancel();
      }

      list.dispose();
    });

    test('监听器应该读取到更新后的值', () {
      final list = RxList<int>([10, 20, 30]);

      int? receivedValue;

      final cancel = list.listenByKey(1, (value) {
        receivedValue = value;
      });

      list[1] = 999;

      expect(receivedValue, 999);
      expect(list.value[1], 999);

      cancel();
      list.dispose();
    });
  });
}
