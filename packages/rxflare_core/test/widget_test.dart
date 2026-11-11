import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_core/rxflare_core.dart';

void main() {
  testWidgets('Rx rebuilds when obs value changes', (WidgetTester tester) async {
    final count = 0.obs;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Rx(() => Text('count=${count.value}', textDirection: TextDirection.ltr)),
          floatingActionButton: FloatingActionButton(
            onPressed: () => count.value++,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );

    expect(find.text('count=0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('count=1'), findsOneWidget);
  });

  testWidgets('batch coalesces multiple updates into one rebuild', (WidgetTester tester) async {
    final a = 0.obs;
    final b = 0.obs;
    var builds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Rx(() {
          builds++;
          return Text('a=${a.value} b=${b.value}', textDirection: TextDirection.ltr);
        }),
      ),
    );

    final buildsAfterFirstFrame = builds;

    batch(() {
      a.value = 1;
      b.value = 2;
    });
    await tester.pump();

    expect(find.text('a=1 b=2'), findsOneWidget);
    expect(builds, buildsAfterFirstFrame + 1);
  });
}
