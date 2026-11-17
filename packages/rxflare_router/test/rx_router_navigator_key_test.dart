// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_router/rxflare_router.dart';

void main() {
  final router = RxRouter.I;

  testWidgets(
    'RxRouter navigatorKey should control the rendered Navigator',
    (tester) async {
      router.memPages.value = [];
      router.tabPages.clear();
      router.activeTabIndex.value = 0;

      router.ensureInitialized();

      final delegate = RxRouterDelegate();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: delegate,
          routeInformationParser: RxRouteParser(),
        ),
      );

      await tester.pumpAndSettle();
      // ignore: avoid_print
      print(
        'RxRouter.navigatorKey.currentState: '
        '${router.navigatorKey.currentState}',
      );
      // ignore: avoid_print
      print(
        'Delegate.navigatorKey.currentState: '
        '${delegate.navigatorKey.currentState}',
      );

      // 公共 Router Key 应当能够访问实际运行的 Navigator。
// 两个 Key 必须是同一个对象。
      expect(
        delegate.navigatorKey,
        same(router.navigatorKey),
      );

// Router 单例的 Key 必须能访问实际 Navigator。
      expect(
        router.navigatorKey.currentState,
        isNotNull,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      delegate.dispose();
    },
  );
}
