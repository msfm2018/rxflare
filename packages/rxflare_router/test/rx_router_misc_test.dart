import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_router/rxflare_router.dart';

import 'helpers/router_test_utils.dart';

void main() {
  final router = RxRouter.I;
  const timeout = Duration(milliseconds: 500);

  setUp(() {
    resetRouter();

    router.register({
      '/': RxRoute(builder: () => const SizedBox()),
      '/home': RxRoute(builder: () => const SizedBox()),
      '/detail': RxRoute(builder: () => const SizedBox()),
      '/login': RxRoute(builder: () => const SizedBox()),
      // key 本身就是带参数的模式，没有单独指定 path。
      '/post/:id': RxRoute(builder: () => const SizedBox()),
    });

    router.ensureInitialized();
  });

  group('globals', () {
    test('rxr is the RxRouter singleton', () {
      expect(identical(rxr, RxRouter.I), isTrue);
    });
  });

  group('RxRouteConfig', () {
    test('home() points to "/" and has no state', () {
      final config = RxRouteConfig.home();

      expect(config.location, '/');
      expect(config.state, isNull);
    });

    test('keeps the given location and state', () {
      final config = RxRouteConfig(location: '/detail/1', state: 'extra');

      expect(config.location, '/detail/1');
      expect(config.state, 'extra');
    });
  });

  group('route keys that already contain a pattern', () {
    test('matches without RxRoute.path and keeps the key as the name', () {
      unawaited(router.to('/post/5'));

      expect(router.current!.name, '/post/:id');
      expect(router.param('id'), '5');
    });

    test('currentConfiguration restores the concrete path and query', () {
      unawaited(router.to('/post/5?ref=home'));

      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      expect(delegate.currentConfiguration, '/post/5?ref=home');
    });
  });

  group('query parameters', () {
    test('are percent-decoded', () {
      unawaited(
        router.to('/detail?name=hello%20world&city=%E5%8C%97%E4%BA%AC'),
      );

      expect(router.queryItem('name'), 'hello world');
      expect(router.queryItem('city'), '北京');
    });
  });

  group('guards (edge cases)', () {
    test('a throwing guard propagates the error and keeps the stack', () async {
      router.register({
        '/boom': RxRoute(
          builder: () => const SizedBox(),
          guard: () async {
            throw StateError('boom');
          },
        ),
      });

      await expectLater(router.to('/boom'), throwsA(isA<StateError>()));

      expect(namesOf(router.memPages.value), ['/']);
    });

    test('a navigating guard pushes onto the active tab stack', () async {
      router.initTab(0, [testPage('/home', 'tab0_root')]);
      router.register({
        '/admin': RxRoute(
          builder: () => const SizedBox(),
          guard: () async {
            final result = await router.to<String>('/login');
            return result == 'ok';
          },
        ),
      });

      final future = router.to<String>('/admin');
      await flushAsync();

      expect(namesOf(router.tabPages[0]!.value), ['/home', '/login']);

      router.back(result: 'ok');
      await flushAsync();

      expect(namesOf(router.tabPages[0]!.value), ['/home', '/admin']);
      expect(namesOf(router.memPages.value), ['/']);

      router.back(result: 'done');
      expect(await future.timeout(timeout), 'done');
    });
  });

  group('tab stack notifications', () {
    test('initTabIfNeeded notifies a root delegate once when it creates one',
        () {
      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);
      var count = 0;
      delegate.addListener(() => count++);

      router.initTabIfNeeded(0, [testPage('/home', 'tab0_root')]);

      expect(count, 1);
    });

    test('initTabIfNeeded does not notify when the stack already exists', () {
      router.initTab(0, [testPage('/home', 'tab0_root')]);
      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);
      var count = 0;
      delegate.addListener(() => count++);

      router.initTabIfNeeded(0, [testPage('/me', 'other_root')]);

      expect(count, 0);
    });

    test('a stack replaced by initTab is observed by an existing delegate', () {
      router.initTab(0, [testPage('/home', 'old_root')]);
      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);
      var count = 0;
      delegate.addListener(() => count++);

      router.initTab(0, [testPage('/home', 'new_root')]);
      expect(count, 1);

      router.tabPages[0]!.value = [testPage('/me', 'newer_root')];

      expect(count, greaterThan(1));
    });
  });
}
