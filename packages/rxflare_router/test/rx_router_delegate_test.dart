import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_router/rxflare_router.dart';

import 'helpers/router_test_utils.dart';

void main() {
  final router = RxRouter.I;

  setUp(() {
    resetRouter();

    router.register({
      '/': RxRoute(builder: () => const SizedBox()),
      '/home': RxRoute(builder: () => const SizedBox()),
      '/detail': RxRoute(
        path: '/detail/:id',
        builder: () => const SizedBox(),
      ),
      '/shop': RxRoute(
        path: '/shop/:shopId/item/:itemId',
        builder: () => const SizedBox(),
      ),
    });
  });

  group('currentConfiguration (root delegate)', () {
    test('is "/" for the root page', () {
      router.memPages.value = [testPage('/', 'p0')];

      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      expect(delegate.currentConfiguration, '/');
    });

    test('is the path of a static route', () {
      router.memPages.value = [testPage('/home', 'p0')];

      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      expect(delegate.currentConfiguration, '/home');
    });

    test('restores a dynamic path parameter', () {
      router.memPages.value = [
        testPage('/detail', 'p0', params: {'id': '123'}),
      ];

      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      expect(delegate.currentConfiguration, '/detail/123');
    });

    test('restores several dynamic path parameters', () {
      router.memPages.value = [
        testPage('/shop', 'p0', params: {'shopId': 's1', 'itemId': 'i2'}),
      ];

      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      expect(delegate.currentConfiguration, '/shop/s1/item/i2');
    });

    test('appends the query string', () {
      router.memPages.value = [
        testPage('/home', 'p0', query: {'a': '1', 'b': '2'}),
      ];

      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      expect(delegate.currentConfiguration, '/home?a=1&b=2');
    });

    test('has no "?" when the query is empty', () {
      router.memPages.value = [testPage('/home', 'p0')];

      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      expect(delegate.currentConfiguration, isNot(contains('?')));
    });

    test('falls back to the page name for an unregistered route', () {
      router.memPages.value = [testPage('/legacy', 'p0')];

      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      expect(delegate.currentConfiguration, '/legacy');
    });

    test('uses the top page of the stack', () {
      router.memPages.value = [
        testPage('/home', 'p0'),
        testPage('/detail', 'p1', params: {'id': '5'}),
      ];

      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      expect(delegate.currentConfiguration, '/detail/5');
    });

    test('ignores tab stacks and keeps reporting the global stack', () {
      // 回归：底部导航栏被 tab 栈顶替的问题。
      router.memPages.value = [testPage('/home', 'g0')];
      router.initTab(0, [
        testPage('/detail', 't0', params: {'id': '7'}),
      ]);

      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      expect(delegate.currentConfiguration, '/home');
    });
  });

  group('currentConfiguration (custom stack delegate)', () {
    test('reports the top page of its own stack', () {
      router.memPages.value = [testPage('/home', 'g0')];
      router.initTab(0, [
        testPage('/detail', 't0', params: {'id': '7'}),
      ]);

      final delegate = RxRouterDelegate(customStack: router.tabPages[0]);
      addTearDown(delegate.dispose);

      expect(delegate.currentConfiguration, '/detail/7');
    });

    test('is "/" when its stack is empty', () {
      router.initTab(0, []);

      final delegate = RxRouterDelegate(customStack: router.tabPages[0]);
      addTearDown(delegate.dispose);

      expect(delegate.currentConfiguration, '/');
    });

    test('follows changes of its own stack', () {
      router.initTab(0, [testPage('/home', 't0')]);

      final delegate = RxRouterDelegate(customStack: router.tabPages[0]);
      addTearDown(delegate.dispose);
      expect(delegate.currentConfiguration, '/home');

      router.tabPages[0]!.value = [
        ...router.tabPages[0]!.value,
        testPage('/detail', 't1', params: {'id': '9'}),
      ];

      expect(delegate.currentConfiguration, '/detail/9');
    });
  });

  group('setNewRoutePath', () {
    test('pushes the requested path when it differs from the current page',
        () async {
      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      await delegate.setNewRoutePath('/home');

      expect(namesOf(router.memPages.value), ['/', '/home']);
    });

    test('does nothing when the path equals the current page name', () async {
      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      await delegate.setNewRoutePath('/home');
      await delegate.setNewRoutePath('/home');

      expect(namesOf(router.memPages.value), ['/', '/home']);
    });

    test('ignores an unknown path', () async {
      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      await delegate.setNewRoutePath('/does-not-exist');

      expect(namesOf(router.memPages.value), ['/']);
    });
  });

  group('construction', () {
    test('a root delegate initializes the global stack', () {
      router.memPages.value = [];
      router.initialRoute = '/home';

      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      expect(namesOf(router.memPages.value), ['/home']);
    });

    test('a root delegate shares the singleton navigatorKey', () {
      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      expect(delegate.navigatorKey, same(router.navigatorKey));
    });

    test('a keyed delegate uses its own navigatorKey', () {
      router.initTab(0, [testPage('/home', 't0')]);

      final delegate = KeyedRxRouterDelegate(customStack: router.tabPages[0]);
      addTearDown(delegate.dispose);

      expect(delegate.navigatorKey, isNot(same(router.navigatorKey)));
    });
  });

  group('subscriptions', () {
    test('root delegate notifies when the global stack changes', () {
      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);
      var count = 0;
      delegate.addListener(() => count++);

      unawaited(router.to('/home'));

      expect(count, greaterThanOrEqualTo(1));
    });

    test('root delegate notifies when a tab stack changes', () {
      router.initTab(0, [testPage('/home', 't0')]);
      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);
      var count = 0;
      delegate.addListener(() => count++);

      router.tabPages[0]!.value = [
        ...router.tabPages[0]!.value,
        testPage('/detail', 't1', params: {'id': '1'}),
      ];

      expect(count, greaterThanOrEqualTo(1));
    });

    test('custom stack delegate notifies when its own stack changes', () {
      router.initTab(0, [testPage('/home', 't0')]);
      final delegate = RxRouterDelegate(customStack: router.tabPages[0]);
      addTearDown(delegate.dispose);
      var count = 0;
      delegate.addListener(() => count++);

      router.tabPages[0]!.value = [
        ...router.tabPages[0]!.value,
        testPage('/detail', 't1', params: {'id': '1'}),
      ];

      expect(count, greaterThanOrEqualTo(1));
    });

    test('custom stack delegate ignores global stack changes', () {
      router.initTab(0, [testPage('/home', 't0')]);
      final delegate = RxRouterDelegate(customStack: router.tabPages[0]);
      addTearDown(delegate.dispose);
      var count = 0;
      delegate.addListener(() => count++);

      router.memPages.value = [
        ...router.memPages.value,
        testPage('/home', 'g1'),
      ];

      expect(count, 0);
    });

    test('custom stack delegate ignores active tab changes', () {
      router.initTab(0, [testPage('/home', 't0')]);
      final delegate = RxRouterDelegate(customStack: router.tabPages[0]);
      addTearDown(delegate.dispose);
      var count = 0;
      delegate.addListener(() => count++);

      router.switchTab(5);

      expect(count, 0);
    });

    test('custom stack delegate ignores other tab stacks', () {
      router.initTab(0, [testPage('/home', 't0')]);
      router.initTab(1, [testPage('/home', 'u0')]);
      final delegate = RxRouterDelegate(customStack: router.tabPages[0]);
      addTearDown(delegate.dispose);
      var count = 0;
      delegate.addListener(() => count++);

      router.tabPages[1]!.value = [
        ...router.tabPages[1]!.value,
        testPage('/detail', 'u1', params: {'id': '1'}),
      ];

      expect(count, 0);
    });

    test('a disposed root delegate is unbound from every stack', () {
      router.initTab(0, [testPage('/home', 't0')]);
      final delegate = RxRouterDelegate();

      delegate.dispose();

      // 如果 dispose 没有解绑，下面的赋值会让已释放的 Delegate 再次 notifyListeners，
      // debug 模式下会抛出断言错误。
      expect(() {
        router.memPages.value = [testPage('/home', 'g1')];
        router.tabPages[0]!.value = [testPage('/home', 't1')];
        router.switchTab(3);
      }, returnsNormally);
    });

    test('a disposed custom stack delegate is unbound from its stack', () {
      router.initTab(0, [testPage('/home', 't0')]);
      final delegate = RxRouterDelegate(customStack: router.tabPages[0]);

      delegate.dispose();

      expect(() {
        router.tabPages[0]!.value = [testPage('/home', 't1')];
      }, returnsNormally);
    });
  });

  group('RxRouteParser', () {
    final parser = RxRouteParser();

    test('parseRouteInformation returns the uri as a string', () async {
      final result = await parser.parseRouteInformation(
        RouteInformation(uri: Uri.parse('/detail/1?x=2')),
      );

      expect(result, '/detail/1?x=2');
    });

    test('restoreRouteInformation builds a RouteInformation', () {
      final info = parser.restoreRouteInformation('/detail/1?x=2');

      expect(info.uri.toString(), '/detail/1?x=2');
    });

    test('round trip keeps the location', () async {
      const location = '/shop/s1/item/i2?from=home';

      final configuration = await parser.parseRouteInformation(
        RouteInformation(uri: Uri.parse(location)),
      );
      final info = parser.restoreRouteInformation(configuration);

      expect(info.uri.toString(), location);
    });
  });
}
