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
      '/user': RxRoute(
        path: '/user/:id',
        builder: () => Text('user ${router.param('id')}'),
      ),
    };
  }

  setUp(resetRouter);

  group('RxWidgetsApp', () {
    testWidgets('renders the default initial route "/"', (tester) async {
      await tester.pumpWidget(RxWidgetsApp(routes: routes()));
      await tester.pumpAndSettle();

      expect(find.text('root page'), findsOneWidget);
      expect(namesOf(router.memPages.value), ['/']);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('registers the given routes with the router', (tester) async {
      await tester.pumpWidget(RxWidgetsApp(routes: routes()));
      await tester.pumpAndSettle();

      unawaited(router.to('/detail'));
      await tester.pumpAndSettle();

      expect(find.text('detail page'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('back returns to the previous page', (tester) async {
      await tester.pumpWidget(RxWidgetsApp(routes: routes()));
      await tester.pumpAndSettle();

      unawaited(router.to('/detail'));
      await tester.pumpAndSettle();

      router.back();
      await tester.pumpAndSettle();

      expect(find.text('detail page'), findsNothing);
      expect(find.text('root page'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('passes path parameters to the page builder', (tester) async {
      await tester.pumpWidget(RxWidgetsApp(routes: routes()));
      await tester.pumpAndSettle();

      unawaited(router.to('/user/7'));
      await tester.pumpAndSettle();

      expect(find.text('user 7'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('honours a custom initialRoute', (tester) async {
      await tester.pumpWidget(
        RxWidgetsApp(
          initialRoute: '/detail',
          // 平台默认的初始地址是 "/"，会让路由器在栈顶再压入一个 "/"，
          // 所以这里显式指定与 initialRoute 一致的初始地址。
          routeInformationProvider: PlatformRouteInformationProvider(
            initialRouteInformation: RouteInformation(
              uri: Uri.parse('/detail'),
            ),
          ),
          routes: routes(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('detail page'), findsOneWidget);
      expect(find.text('root page'), findsNothing);
      expect(router.initialRoute, '/detail');
      expect(namesOf(router.memPages.value), ['/detail']);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('releases its delegate subscriptions on dispose',
        (tester) async {
      await tester.pumpWidget(RxWidgetsApp(routes: routes()));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());

      // dispose 之后再改栈，不应该通知已释放的 Delegate。
      expect(() {
        router.memPages.value = [testPage('/', 'after_dispose')];
      }, returnsNormally);
    });
  });
}
