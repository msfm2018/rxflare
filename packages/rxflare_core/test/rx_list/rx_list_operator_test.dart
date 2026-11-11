import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_core/rxflare_core.dart';

void main() {
  group('RxList operator []=', () {
    test('修改元素应该更新对应索引', () {
      final list = RxList<int>([1, 2, 3]);

      list[1] = 100;

      expect(list.value, [1, 100, 3]);
    });

    test('修改相同值应该保持原始 List', () {
      final list = RxList<int>([1, 2, 3]);

      final oldList = list.value;

      list[1] = 2;

      expect(list.value, [1, 2, 3]);
      expect(identical(list.value, oldList), isTrue);
    });

    test('修改不同索引不应该影响其他元素', () {
      final list = RxList<int>([10, 20, 30, 40]);

      list[2] = 999;

      expect(list.value, [10, 20, 999, 40]);
    });

    test('连续修改应该保持正确结果', () {
      final list = RxList<int>([1, 2, 3]);

      list[0] = 10;
      list[1] = 20;
      list[2] = 30;

      expect(list.value, [10, 20, 30]);
    });

    test('更新不应该修改原始 List', () {
      final original = [1, 2, 3];

      final list = RxList<int>(original);

      list[1] = 100;

      expect(original, [1, 2, 3]);
      expect(list.value, [1, 100, 3]);

      expect(identical(original, list.value), isFalse);
    });

    test('相同复杂对象不应该产生新的 List', () {
      final list = RxList<Map<String, dynamic>>([
        {'id': 1, 'name': 'Tom'},
        {'id': 2, 'name': 'Jack'},
      ]);

      final oldList = list.value;

      list[0] = {'id': 1, 'name': 'Tom'};

      expect(identical(list.value, oldList), isTrue);
    });

    test('不同复杂对象应该正常更新', () {
      final list = RxList<Map<String, dynamic>>([
        {'id': 1, 'name': 'Tom'},
        {'id': 2, 'name': 'Jack'},
      ]);

      list[0] = {'id': 1, 'name': 'Alice'};

      expect(list.value[0]['name'], 'Alice');
      expect(list.value[1]['name'], 'Jack');
    });

    test('负数索引应该抛出 RangeError', () {
      final list = RxList<int>([1, 2, 3]);

      expect(
        () => list[-1] = 100,
        throwsRangeError,
      );
    });

    test('超出范围的索引应该抛出 RangeError', () {
      final list = RxList<int>([1, 2, 3]);

      expect(
        () => list[3] = 100,
        throwsRangeError,
      );
    });
  });
}
