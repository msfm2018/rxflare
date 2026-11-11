import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_core/rxflare_core.dart';

void main() {
  RxDebug.isEnabled = true;
  group('Rx Widget Fine-Grained Rebuild', () {
    testWidgets(
      '修改 Index 0 只应该重建读取 Index 0 的 Widget',
      (tester) async {
        final list = RxList<int>([10, 20]);

        var build0 = 0;
        var build1 = 0;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                Rx(() {
                  build0++;
                  return Text(
                    '${list[0]}',
                    key: const ValueKey('item0'),
                  );
                }),
                Rx(() {
                  build1++;
                  return Text(
                    '${list[1]}',
                    key: const ValueKey('item1'),
                  );
                }),
              ],
            ),
          ),
        );

        // 排除首次构建
        build0 = 0;
        build1 = 0;

        list[0] = 100;

        await tester.pump();

        expect(build0, 1);
        expect(build1, 0);

        expect(find.text('100'), findsOneWidget);
        expect(find.text('20'), findsOneWidget);
      },
    );

    testWidgets(
      '修改 Index 1 只应该重建读取 Index 1 的 Widget',
      (tester) async {
        final list = RxList<int>([10, 20]);

        var build0 = 0;
        var build1 = 0;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                Rx(() {
                  build0++;
                  return Text('${list[0]}');
                }),
                Rx(() {
                  build1++;
                  return Text('${list[1]}');
                }),
              ],
            ),
          ),
        );

        build0 = 0;
        build1 = 0;

        list[1] = 200;

        await tester.pump();

        expect(build0, 0);
        expect(build1, 1);

        expect(find.text('10'), findsOneWidget);
        expect(find.text('200'), findsOneWidget);
      },
    );

    testWidgets(
      '整体 value 更新应该重建读取整体 List 的 Widget',
      (tester) async {
        final list = RxList<int>([10, 20]);

        var buildCount = 0;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Rx(() {
              buildCount++;

              return Text(
                list.value.join(','),
              );
            }),
          ),
        );

        buildCount = 0;

        list.value = [100, 200];

        await tester.pump();

        expect(buildCount, 1);
        expect(find.text('100,200'), findsOneWidget);
      },
    );
  });
}