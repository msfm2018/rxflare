import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_core/rxflare_core.dart';

void main() {
  group('RxList bulk update reproduction', () {
    test('updateWhere should reveal global and index notifications', () {
      final list = RxList<int>([10, 20, 30]);

      var globalCount = 0;
      final indexCounts = [0, 0, 0];

      final cancelGlobal = list.listen((_) {
        globalCount++;
      });

      final cancels = List.generate(3, (index) {
        return list.listenByKey(index, (_) {
          indexCounts[index]++;
        });
      });

      // 排除监听注册时的初始回调
      globalCount = 0;
      indexCounts.fillRange(0, 3, 0);

      list.updateWhere(
        (item) => item >= 20,
        (item) => item * 10,
      );
      // ignore: avoid_print
      print('updateWhere 结果: ${list.value}');
      // ignore: avoid_print
      print('全局通知次数: $globalCount');
      // ignore: avoid_print
      print('索引通知次数: $indexCounts');

      expect(list.value, [10, 200, 300]);

      // 当前源码的实际行为
      expect(globalCount, 0);
      expect(indexCounts, [0, 1, 1]);

      cancelGlobal();
      for (final cancel in cancels) {
        cancel();
      }
      list.dispose();
    });

    test('replaceWhere should reveal global and index notifications', () {
      final list = RxList<int>([10, 20, 20, 40]);

      var globalCount = 0;
      final indexCounts = [0, 0, 0, 0];

      final cancelGlobal = list.listen((_) {
        globalCount++;
      });

      final cancels = List.generate(4, (index) {
        return list.listenByKey(index, (_) {
          indexCounts[index]++;
        });
      });

      globalCount = 0;
      indexCounts.fillRange(0, 4, 0);

      list.replaceWhere(
        (item) => item == 20,
        99,
      );
      // ignore: avoid_print
      print('replaceWhere 结果: ${list.value}');
      // ignore: avoid_print
      print('全局通知次数: $globalCount');
      // ignore: avoid_print
      print('索引通知次数: $indexCounts');

      expect(list.value, [10, 99, 99, 40]);

      // 当前源码的实际行为
      expect(globalCount, 0);
      expect(indexCounts, [0, 1, 1, 0]);

      cancelGlobal();
      for (final cancel in cancels) {
        cancel();
      }
      list.dispose();
    });
  });
}
