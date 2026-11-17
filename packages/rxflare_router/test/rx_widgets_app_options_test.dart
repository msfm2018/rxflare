import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_router/rxflare_router.dart';

import 'helpers/router_test_utils.dart';

void main() {
  final router = RxRouter.I;

  Map<String, RxRoute> routes() {
    return {
      '/': RxRoute(builder: () => const Text('root page')),
      '/detail': RxRoute(builder: () => const Text('detail page')),
    };
  }

  setUp(resetRouter);

  group('RxWidgetsApp options', () {
    testWidgets('builder wraps the router output', (tester) async {
      await tester.pumpWidget(
        RxWidgetsApp(
          routes: routes(),
          builder: (context, child) {
            return Column(
              children: [
                const Text('banner'),
                Expanded(child: child!),
              ],
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('banner'), findsOneWidget);
      expect(find.text('root page'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('the debug banner is hidden by default', (tester) async {
      await tester.pumpWidget(RxWidgetsApp(routes: routes()));
      await tester.pumpAndSettle();

      expect(find.byType(CheckedModeBanner), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('the debug banner can be turned on', (tester) async {
      await tester.pumpWidget(
        RxWidgetsApp(routes: routes(), debugShowCheckedModeBanner: true),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CheckedModeBanner), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('routes are registered only once, not on every rebuild',
        (tester) async {
      late StateSetter rebuild;
      var useSecondRoutes = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return RxWidgetsApp(
                routes: useSecondRoutes
                    ? {
                        '/': RxRoute(builder: () => const Text('root page')),
                        '/extra': RxRoute(
                          builder: () => const Text('extra page'),
                        ),
                      }
                    : routes(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      rebuild(() => useSecondRoutes = true);
      await tester.pump();

      // 第二份路由表里的 /extra 不会被注册。
      final result = await router.to('/extra');
      expect(result, isNull);
      expect(namesOf(router.memPages.value), ['/']);

      // 第一份路由表里的 /detail 仍然可用。
      unawaited(router.to('/detail'));
      await tester.pumpAndSettle();
      expect(find.text('detail page'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
