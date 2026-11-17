import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_router/rxflare_router.dart';

import 'helpers/router_test_utils.dart';

void main() {
  final router = RxRouter.I;
  const timeout = Duration(milliseconds: 500);

  List<String> names() => namesOf(router.memPages.value);

  setUp(() {
    resetRouter();

    router.register({
      '/': RxRoute(builder: () => const SizedBox()),
      '/detail': RxRoute(builder: () => const SizedBox()),
      '/replacement': RxRoute(builder: () => const SizedBox()),
      '/home': RxRoute(builder: () => const SizedBox()),
      '/login': RxRoute(builder: () => const SizedBox()),
      '/user': RxRoute(path: '/user/:id', builder: () => const SizedBox()),
      '/blocked': RxRoute(
        builder: () => const SizedBox(),
        guard: () async => false,
      ),
      '/allowed': RxRoute(
        builder: () => const SizedBox(),
        guard: () async => true,
      ),
    });

    router.ensureInitialized();
  });

  group('ensureInitialized', () {
    test('creates the initial route page when the stack is empty', () {
      router.memPages.value = [];
      router.initialRoute = '/home';

      router.ensureInitialized();

      expect(names(), ['/home']);
    });

    test('is idempotent', () {
      final firstId = router.memPages.value.single.pageId;

      router.ensureInitialized();
      router.ensureInitialized();

      expect(router.memPages.value, hasLength(1));
      expect(router.memPages.value.single.pageId, firstId);
    });

    test('does not touch an existing stack', () {
      unawaited(router.to('/detail'));

      router.ensureInitialized();

      expect(names(), ['/', '/detail']);
    });
  });

  group('register', () {
    test('uses the map key as the path when path is omitted', () {
      unawaited(router.to('/detail'));

      expect(router.current!.name, '/detail');
      expect(router.params(), isEmpty);
    });

    test('matches with RxRoute.path and keeps the key as page name', () {
      unawaited(router.to('/user/42'));

      expect(router.current!.name, '/user');
      expect(router.param('id'), '42');
    });

    test('the key itself no longer matches when path overrides it', () async {
      final result = await router.to('/user');

      expect(result, isNull);
      expect(names(), ['/']);
    });
  });

  group('current / pageId / accessors on an empty stack', () {
    test('return null or empty values', () {
      router.memPages.value = [];

      expect(router.current, isNull);
      expect(router.pageId(), isNull);
      expect(router.args<Object>(), isNull);
      expect(router.query(), isEmpty);
      expect(router.params(), isEmpty);
      expect(router.queryItem('id'), isNull);
      expect(router.param('id'), isNull);
    });
  });

  group('to', () {
    test('pushes the page onto the global stack', () {
      unawaited(router.to('/detail'));

      expect(names(), ['/', '/detail']);
      expect(router.current!.name, '/detail');
    });

    test('returns null and keeps the stack for an unknown path', () async {
      final result = await router.to('/does-not-exist');

      expect(result, isNull);
      expect(names(), ['/']);
    });

    test('gives every pushed page a unique pageId', () {
      unawaited(router.to('/detail'));
      unawaited(router.to('/detail'));

      final ids = router.memPages.value.map((p) => p.pageId).toSet();

      expect(ids, hasLength(3));
    });

    test('parses query parameters', () {
      unawaited(router.to('/detail?id=123&type=vip'));

      expect(router.query(), {'id': '123', 'type': 'vip'});
      expect(router.queryItem('id'), '123');
      expect(router.queryItem('type'), 'vip');
      expect(router.queryItem('missing'), isNull);
    });

    test('parses path parameters together with query parameters', () {
      unawaited(router.to('/user/42?tab=profile'));

      expect(router.params(), {'id': '42'});
      expect(router.param('id'), '42');
      expect(router.param('missing'), isNull);
      expect(router.queryItem('tab'), 'profile');
    });

    test('stores arguments for the new page', () {
      unawaited(router.to('/detail', arguments: {'name': 'ZhangSan'}));

      expect(router.args<Map>(), {'name': 'ZhangSan'});
    });

    test('args is null when no arguments were passed', () {
      unawaited(router.to('/detail'));

      expect(router.args<Object>(), isNull);
    });

    test('arguments belong to their own page', () {
      unawaited(router.to('/detail', arguments: 'first'));
      unawaited(router.to('/user/1', arguments: 'second'));

      expect(router.args<String>(), 'second');

      router.back();

      expect(router.args<String>(), 'first');
    });

    test('the returned future completes with the back result', () async {
      final future = router.to<String>('/detail');

      router.back(result: 'done');

      expect(await future.timeout(timeout), 'done');
    });

    test('results go to the matching awaiter (LIFO)', () async {
      final first = router.to<String>('/detail');
      final second = router.to<String>('/user/1');

      router.back(result: 'second');
      router.back(result: 'first');

      expect(await second.timeout(timeout), 'second');
      expect(await first.timeout(timeout), 'first');
    });
  });

  group('guards', () {
    test('a guard returning false blocks the navigation', () async {
      final result = await router.to('/blocked');

      expect(result, isNull);
      expect(names(), ['/']);
    });

    test('a guard returning true lets the navigation through', () async {
      final future = router.to<String>('/allowed');
      await flushAsync();

      expect(names(), ['/', '/allowed']);

      router.back(result: 'ok');

      expect(await future.timeout(timeout), 'ok');
    });

    test('the guard runs exactly once per navigation', () async {
      var calls = 0;
      router.register({
        '/counted': RxRoute(
          builder: () => const SizedBox(),
          guard: () async {
            calls++;
            return true;
          },
        ),
      });

      unawaited(router.to('/counted'));
      await flushAsync();

      expect(calls, 1);
      expect(names(), ['/', '/counted']);
    });

    test('the page is not pushed before the guard has finished', () async {
      final gate = Completer<bool>();
      router.register({
        '/gated': RxRoute(
          builder: () => const SizedBox(),
          guard: () => gate.future,
        ),
      });

      unawaited(router.to('/gated'));
      await flushAsync();

      expect(names(), ['/']);

      gate.complete(true);
      await flushAsync();

      expect(names(), ['/', '/gated']);
    });

    test('a guard may navigate (login flow) and allow on success', () async {
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

      // 守卫先把登录页压栈。
      expect(names(), ['/', '/login']);

      router.back(result: 'ok');
      await flushAsync();

      // 登录成功后目标页才入栈。
      expect(names(), ['/', '/admin']);

      router.back(result: 'done');
      expect(await future.timeout(timeout), 'done');
    });

    test('a guard that navigates blocks the target when login fails', () async {
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

      router.back(result: 'cancel');

      expect(await future.timeout(timeout), isNull);
      expect(names(), ['/']);
    });

    test('off respects guards', () async {
      unawaited(router.to('/detail'));

      final result = await router.off('/blocked');

      expect(result, isNull);
      expect(names(), ['/', '/detail']);
    });

    test('offAll respects guards', () async {
      unawaited(router.to('/detail'));

      final result = await router.offAll('/blocked');

      expect(result, isNull);
      expect(names(), ['/', '/detail']);
    });
  });

  group('back', () {
    test('pops the top page', () {
      unawaited(router.to('/detail'));
      unawaited(router.to('/user/1'));

      router.back();

      expect(names(), ['/', '/detail']);
      expect(router.current!.name, '/detail');
    });

    test('does nothing when only one page is left', () {
      router.back();
      router.back();

      expect(names(), ['/']);
    });

    test('completes the future with null when no result is given', () async {
      final future = router.to<String>('/detail');

      router.back();

      expect(await future.timeout(timeout), isNull);
    });

    test('removes the arguments of the popped page', () {
      unawaited(router.to('/detail', arguments: 'payload'));
      final pageId = router.pageId()!;
      expect(RxArgs.I.get<String>(pageId), 'payload');

      router.back();

      expect(RxArgs.I.get<String>(pageId), isNull);
    });
  });

  group('off', () {
    test('replaces the top page', () {
      unawaited(router.to('/detail'));

      unawaited(router.off('/replacement'));

      expect(names(), ['/', '/replacement']);
    });

    test('replaces the root page when only one page exists', () {
      unawaited(router.off('/replacement'));

      expect(names(), ['/replacement']);
    });

    test('completes the removed page future with null', () async {
      final removed = router.to<int>('/detail');

      unawaited(router.off<void>('/replacement'));

      expect(await removed.timeout(timeout), isNull);
    });

    test('removes the arguments of the replaced page', () {
      unawaited(router.to('/detail', arguments: 'payload'));
      final oldId = router.pageId()!;

      unawaited(router.off('/replacement'));

      expect(RxArgs.I.get<String>(oldId), isNull);
    });

    test('the new page future receives the back result', () async {
      unawaited(router.to('/detail'));
      final replacement = router.off<String>('/replacement');

      router.back(result: 'from replacement');

      expect(await replacement.timeout(timeout), 'from replacement');
    });

    test('returns null and keeps the stack for an unknown path', () async {
      unawaited(router.to('/detail'));

      final result = await router.off('/does-not-exist');

      expect(result, isNull);
      expect(names(), ['/', '/detail']);
    });
  });

  group('offAll', () {
    test('leaves only the target page in the stack', () {
      unawaited(router.to('/detail'));
      unawaited(router.to('/user/1'));

      unawaited(router.offAll('/home'));

      expect(names(), ['/home']);
    });

    test('completes every removed page future with null', () async {
      final first = router.to<int>('/detail');
      final second = router.to<int>('/user/1');

      unawaited(router.offAll<void>('/home'));

      expect(await first.timeout(timeout), isNull);
      expect(await second.timeout(timeout), isNull);
    });

    test('removes the arguments of every removed page', () {
      unawaited(router.to('/detail', arguments: 'a'));
      final firstId = router.pageId()!;
      unawaited(router.to('/user/1', arguments: 'b'));
      final secondId = router.pageId()!;

      unawaited(router.offAll('/home'));

      expect(RxArgs.I.get<String>(firstId), isNull);
      expect(RxArgs.I.get<String>(secondId), isNull);
    });

    test('back does nothing afterwards because only one page is left', () {
      unawaited(router.to('/detail'));
      unawaited(router.offAll('/home'));

      router.back();

      expect(names(), ['/home']);
    });

    test('returns null and keeps the stack for an unknown path', () async {
      unawaited(router.to('/detail'));

      final result = await router.offAll('/does-not-exist');

      expect(result, isNull);
      expect(names(), ['/', '/detail']);
    });
  });
}
