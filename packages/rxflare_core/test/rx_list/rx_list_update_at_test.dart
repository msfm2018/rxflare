import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_core/rxflare_core.dart';

void main() {
  test('RxList.updateAt should respect notifyGlobal', () async {
    final list = RxList<int>([1, 2]);

    var globalCount = 0;
    var indexCount = 0;

    final cancelGlobal = list.listen((value) {
      globalCount++;
    });

    final cancelIndex = list.listenByKey(0, (value) {
      indexCount++;
    });

    // 忽略订阅时的初始回调。
    globalCount = 0;
    indexCount = 0;

    // 场景一：默认 notifyGlobal = false。
    list.updateAt(0, 10);

    await Future<void>.delayed(Duration.zero);

    expect(list.value, [10, 2]);
    expect(globalCount, 0);
    expect(indexCount, 1);

    // 场景二：notifyGlobal = true。
    globalCount = 0;
    indexCount = 0;

    list.updateAt(0, 20, notifyGlobal: true);

    await Future<void>.delayed(Duration.zero);

    expect(list.value, [20, 2]);
    expect(
      globalCount,
      1,
      reason: 'notifyGlobal=true should notify global listeners.',
    );
    expect(indexCount, 1);

    // 场景三：更新为相同值，不应该产生任何通知。
    globalCount = 0;
    indexCount = 0;

    list.updateAt(0, 20, notifyGlobal: true);

    await Future<void>.delayed(Duration.zero);

    expect(globalCount, 0);
    expect(indexCount, 0);

    cancelGlobal();
    cancelIndex();
    list.dispose();
  });
}
