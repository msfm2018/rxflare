import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'rx_state.dart';
import 'rx_extension.dart';

void main() {
  group('RxState .obs 基础测试', () {
    test('RxState 基础监听', () {
      final state = 0.obs; // 替换 RxState<int>(0)
      int? latest;

      state.listen((v) => latest = v);

      expect(latest, 0);
      state.value = 1;
      expect(latest, 1);
    });

    test('相同值不触发监听', () {
      final state = 1.obs;
      int count = 0;

      state.listen((v) => count++);
      state.value = 1;

      expect(count, 1); // 仅初始触发
    });

    test('取消监听', () {
      final state = 0.obs;
      int count = 0;

      final cancel = state.listen((v) => count++);
      state.value = 1;
      cancel();
      state.value = 2;

      expect(count, 2); // 初始 + 1
    });
  });

  group('容器类型与字段监听', () {
    test('Map 字段监听', () {
      // 泛型 Map 转换
      final state = {"name": "Tom"}.obs;
      String? name;

      state.listenByKey("name", (v) => name = v);
      expect(name, "Tom");

      state.listenByKey("name", "Jerry");
      expect(name, "Jerry");
    });

    // 废弃 list监听
    // test('List 字段监听', () {
    //   final state = [1, 2, 3].obs;
    //   int? item;

    //   state.listenByKey(1, (v) => item = v);
    //   expect(item, 2);

    //   state.updateField(1, 99);
    //   expect(item, 99);
    // });
  });

  group('依赖追踪与 Widget 测试', () {
    test('依赖追踪', () {
      final a = 1.obs;
      final b = 2.obs;
      final deps = <RxState>{};

      RxTrack.startTracking(deps);
      final sum = a.value + b.value;
      RxTrack.stopTracking();

      expect(deps.contains(a), true);
      expect(deps.contains(b), true);
      expect(sum, 3);
    });

    testWidgets('多个依赖更新', (tester) async {
      final a = 1.obs;
      final b = 2.obs;

      await tester.pumpWidget(
        MaterialApp(
          home: Rx(() => Text('${a.value + b.value}', textDirection: TextDirection.ltr)),
        ),
      );

      expect(find.text('3'), findsOneWidget);

      a.value = 2;
      await tester.pump();
      expect(find.text('4'), findsOneWidget);
    });
  });

  group('安全与清理', () {
    test('dispose 后不触发', () {
      final state = 0.obs;
      int count = 0;

      state.listen((_) => count++);
      state.dispose();
      state.value = 1;

      expect(count, 1);
    });

    test('重复取消安全', () {
      final state = 0.obs;
      final cancel = state.listen((_) {});
      cancel();
      cancel(); // 不应崩溃
    });
  });
}
