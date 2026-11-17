import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_router/rxflare_router.dart';

import 'helpers/router_test_utils.dart';

void main() {
  final router = RxRouter.I;
  const timeout = Duration(milliseconds: 500);

  List<String> globalNames() => namesOf(router.memPages.value);
  List<String> tabNames(int index) => namesOf(router.tabPages[index]!.value);

  setUp(() {
    resetRouter();

    router.register({
      '/': RxRoute(builder: () => const SizedBox()),
      '/home': RxRoute(builder: () => const SizedBox()),
      '/me': RxRoute(builder: () => const SizedBox()),
      '/detail': RxRoute(builder: () => const SizedBox()),
      '/replacement': RxRoute(builder: () => const SizedBox()),
      '/user': RxRoute(path: '/user/:id', builder: () => const SizedBox()),
    });

    router.ensureInitialized();
  });

  group('initTab / initTabIfNeeded', () {
    test('initTab creates a stack for the tab', () {
      router.initTab(0, [testPage('/home', 'tab0_root')]);

      expect(tabNames(0), ['/home']);
      expect(router.tabPages[0]!.value.single.pageId, 'tab0_root');
    });

    test('initTab replaces an existing stack', () {
      router.initTab(0, [testPage('/home', 'old_root')]);

      router.initTab(0, [testPage('/me', 'new_root')]);

      expect(tabNames(0), ['/me']);
      expect(router.tabPages[0]!.value.single.pageId, 'new_root');
    });

    test('initTabIfNeeded creates a missing stack', () {
      router.initTabIfNeeded(2, [testPage('/home', 'tab2_root')]);

      expect(tabNames(2), ['/home']);
    });

    test('initTabIfNeeded keeps an existing stack untouched', () {
      router.initTabIfNeeded(0, [testPage('/home', 'first_root')]);

      router.initTabIfNeeded(0, [testPage('/me', 'second_root')]);

      expect(tabNames(0), ['/home']);
      expect(router.tabPages[0]!.value.single.pageId, 'first_root');
    });

    test('initTabIfNeeded keeps pages pushed after the first init', () {
      router.initTabIfNeeded(0, [testPage('/home', 'tab0_root')]);
      unawaited(router.to('/detail'));

      router.initTabIfNeeded(0, [testPage('/home', 'tab0_root')]);

      expect(tabNames(0), ['/home', '/detail']);
    });

    test('tab stacks do not affect the global stack', () {
      router.initTab(0, [testPage('/home', 'tab0_root')]);
      router.initTab(1, [testPage('/me', 'tab1_root')]);

      expect(globalNames(), ['/']);
    });
  });

  group('switchTab / activeTabIndex', () {
    test('activeTabIndex starts at 0', () {
      expect(router.activeTabIndex.value, 0);
    });

    test('switchTab updates activeTabIndex', () {
      router.switchTab(1);
      expect(router.activeTabIndex.value, 1);

      router.switchTab(0);
      expect(router.activeTabIndex.value, 0);
    });
  });

  group('active stack selection', () {
    test('current comes from the global stack before any tab exists', () {
      expect(router.current!.name, '/');
    });

    test('current follows the active tab', () {
      router.initTab(0, [testPage('/home', 'tab0_root')]);
      router.initTab(1, [testPage('/me', 'tab1_root')]);

      expect(router.current!.pageId, 'tab0_root');

      router.switchTab(1);
      expect(router.current!.pageId, 'tab1_root');

      router.switchTab(0);
      expect(router.current!.pageId, 'tab0_root');
    });

    test('falls back to the global stack when the active tab has no stack', () {
      router.initTab(0, [testPage('/home', 'tab0_root')]);

      router.switchTab(5);

      expect(router.current!.name, '/');
    });

    test('pageId / query / params read from the active tab top page', () {
      router.initTab(0, [
        testPage('/home', 'tab0_root', query: {'k': 'v'}),
      ]);

      expect(router.pageId(), 'tab0_root');
      expect(router.queryItem('k'), 'v');

      unawaited(router.to('/user/5?x=1'));

      expect(router.param('id'), '5');
      expect(router.queryItem('x'), '1');
      expect(router.queryItem('k'), isNull);
    });
  });

  group('navigation inside tabs', () {
    setUp(() {
      router.initTab(0, [testPage('/home', 'tab0_root')]);
      router.initTab(1, [testPage('/me', 'tab1_root')]);
    });

    test('to pushes onto the active tab, not onto the global stack', () {
      unawaited(router.to('/detail'));

      expect(tabNames(0), ['/home', '/detail']);
      expect(tabNames(1), ['/me']);
      expect(globalNames(), ['/']);
    });

    test('to follows the active tab after switchTab', () {
      router.switchTab(1);

      unawaited(router.to('/detail'));

      expect(tabNames(0), ['/home']);
      expect(tabNames(1), ['/me', '/detail']);
    });

    test('tab stacks keep their own history when switching', () {
      unawaited(router.to('/detail'));
      router.switchTab(1);
      unawaited(router.to('/user/1'));
      unawaited(router.to('/detail'));

      router.switchTab(0);

      expect(tabNames(0), ['/home', '/detail']);
      expect(tabNames(1), ['/me', '/user', '/detail']);
    });

    test('back pops only the active tab stack', () {
      unawaited(router.to('/detail'));
      router.switchTab(1);
      unawaited(router.to('/detail'));

      router.back();

      expect(tabNames(0), ['/home', '/detail']);
      expect(tabNames(1), ['/me']);
      expect(globalNames(), ['/']);
    });

    test('back at the tab root does nothing and does not pop the global stack',
        () {
      // 让全局栈有两个页面，用来确认 tab 根部的 back 不会穿透到全局栈。
      router.memPages.value = [
        testPage('/', 'g0'),
        testPage('/home', 'g1'),
      ];

      router.switchTab(1);
      router.back();
      router.back();

      expect(tabNames(1), ['/me']);
      expect(globalNames(), ['/', '/home']);
    });

    test('the future of a tab page receives the back result', () async {
      final future = router.to<String>('/detail');

      router.back(result: 'tab-result');

      expect(await future.timeout(timeout), 'tab-result');
    });

    test('off replaces the top page of the active tab only', () {
      unawaited(router.to('/detail'));

      unawaited(router.off('/replacement'));

      expect(tabNames(0), ['/home', '/replacement']);
      expect(tabNames(1), ['/me']);
      expect(globalNames(), ['/']);
    });

    test('offAll resets only the active tab stack', () {
      unawaited(router.to('/detail'));
      router.switchTab(1);
      unawaited(router.to('/detail'));

      unawaited(router.offAll('/replacement'));

      expect(tabNames(1), ['/replacement']);
      expect(tabNames(0), ['/home', '/detail']);
      expect(globalNames(), ['/']);
    });

    test('arguments passed inside a tab are readable and cleaned on back', () {
      unawaited(router.to('/detail', arguments: 'payload'));
      final pageId = router.pageId()!;

      expect(router.args<String>(), 'payload');

      router.back();

      expect(RxArgs.I.get<String>(pageId), isNull);
    });
  });
}
