import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare/rxflare.dart';

class FakeSource {
  FakeSource({this.total = 100});

  final int total;
  final List<int> calledPages = [];
  final Set<int> failOnce = {};

  Future<PageResult<int>> load(int page, int size) async {
    calledPages.add(page);
    if (failOnce.remove(page)) throw Exception('boom');

    final start = page * size;
    final end = math.min(start + size, total);
    return PageResult<int>(
      [for (var i = start; i < end; i++) i * 10],
      totalCount: total,
    );
  }
}

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 10));
  }
}

Widget host(List<Widget> children) => Directionality(
      textDirection: TextDirection.ltr,
      child: Column(children: children),
    );

void main() {
  RxDebug.isEnabled = false;

  group('RxPagedList (widget)', () {
    testWidgets('首次读取触发加载，同一页只请求一次', (tester) async {
      final src = FakeSource();
      final list = RxPagedList<int>(loader: src.load, pageSize: 10);

      await tester.pumpWidget(host([
        for (var i = 0; i < 3; i++)
          Rx(() => Text(list[i]?.toString() ?? '...', key: ValueKey('r$i'))),
      ]));
      await settle(tester);

      expect(find.text('0'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(src.calledPages, [0]);
      expect(list.peekLength, 100);
    });

    testWidgets('updateAt 只重建被修改的那一行', (tester) async {
      final src = FakeSource();
      final list = RxPagedList<int>(loader: src.load, pageSize: 10);
      final builds = [0, 0, 0];

      await tester.pumpWidget(host([
        for (var i = 0; i < 3; i++)
          Rx(() {
            builds[i]++;
            return Text(list[i]?.toString() ?? '...');
          }),
      ]));
      await settle(tester);

      for (var i = 0; i < 3; i++) {
        builds[i] = 0;
      }

      expect(list.updateAt(1, 999), isTrue);
      await settle(tester);

      expect(builds, [0, 1, 0]);
      expect(find.text('999'), findsOneWidget);
    });

    testWidgets('加载失败显示 error，retryPage 后恢复', (tester) async {
      final src = FakeSource()..failOnce.add(0);
      final list = RxPagedList<int>(loader: src.load, pageSize: 10);

      await tester.pumpWidget(host([
        Rx(() {
          final s = list.statusAt(0);
          final v = list[0];
          return Text(s == RxPageStatus.error ? 'err' : (v?.toString() ?? '...'));
        }),
      ]));
      await settle(tester);
      expect(find.text('err'), findsOneWidget);

      list.retryPage(0);
      await settle(tester);

      expect(find.text('0'), findsOneWidget);
      expect(src.calledPages, [0, 0]);
    });

    testWidgets('invalidate 清缓存并重新加载', (tester) async {
      final src = FakeSource();
      final list = RxPagedList<int>(loader: src.load, pageSize: 10);

      await tester.pumpWidget(host([
        Rx(() => Text(list[0]?.toString() ?? '...')),
      ]));
      await settle(tester);
      expect(src.calledPages, [0]);

      list.invalidate();
      await settle(tester);

      expect(src.calledPages, [0, 0]);
      expect(find.text('0'), findsOneWidget);
    });
  });

  group('RxPagedList (unit)', () {
    test('LRU 淘汰最旧的页', () async {
      final src = FakeSource();
      final list = RxPagedList<int>(
        loader: src.load,
        pageSize: 10,
        maxCachedPages: 2,
        autoLoadFirstPage: false,
      );

      await list.ensureLoaded(0);
      await list.ensureLoaded(10);
      await list.ensureLoaded(20);
      await list.ensureLoaded(30);

      expect(list.cachedPages, [2, 3]);
    });

    test('无限滚动：写不满的一页之后不再有哨兵行', () async {
      final list = RxPagedList<int>(
        pageSize: 10,
        autoLoadFirstPage: false,
        loader: (page, size) async {
          final n = page == 1 ? 4 : size; // 第 2 页只有 4 条
          return PageResult<int>([for (var i = 0; i < n; i++) page * size + i]);
        },
      );

      expect(list.peekLength, 1); // 哨兵行

      await list.ensureLoaded(0);
      expect(list.peekLength, 11); // 10 条 + 哨兵

      await list.ensureLoaded(10);
      expect(list.peekLength, 14); // 14 条，没有更多
    });
  });
}
