import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_router/rxflare_router.dart';

import 'helpers/router_test_utils.dart';

void main() {
  final router = RxRouter.I;

  List<String> names() => namesOf(router.memPages.value);

  setUp(() {
    resetRouter();
    registerTextRoutes(['/', '/detail', '/second', '/tab-a', '/tab-b']);
    router.ensureInitialized();
  });

  group('root delegate rendering', () {
    testWidgets('renders the top page of the global stack', (tester) async {
      final delegate = RxRouterDelegate();

      await tester.pumpWidget(hostRouter(delegate));
      await tester.pumpAndSettle();

      expect(find.text('page:/'), findsOneWidget);

      await disposeHost(tester, [delegate]);
    });

    testWidgets('renders 404 for an unregistered route name', (tester) async {
      router.memPages.value = [testPage('/ghost', 'ghost_1')];
      final delegate = RxRouterDelegate();

      await tester.pumpWidget(hostRouter(delegate));
      await tester.pumpAndSettle();

      expect(find.text('404'), findsOneWidget);

      await disposeHost(tester, [delegate]);
    });

    testWidgets('shows a pushed page and returns after back', (tester) async {
      final delegate = RxRouterDelegate();
      await tester.pumpWidget(hostRouter(delegate));
      await tester.pumpAndSettle();

      unawaited(router.to('/detail'));
      await tester.pumpAndSettle();

      expect(find.text('page:/detail'), findsOneWidget);

      router.back();
      await tester.pumpAndSettle();

      expect(find.text('page:/detail'), findsNothing);
      expect(find.text('page:/'), findsOneWidget);

      await disposeHost(tester, [delegate]);
    });

    testWidgets('off swaps the visible page', (tester) async {
      final delegate = RxRouterDelegate();
      await tester.pumpWidget(hostRouter(delegate));
      await tester.pumpAndSettle();

      unawaited(router.to('/detail'));
      await tester.pumpAndSettle();

      unawaited(router.off('/second'));
      await tester.pumpAndSettle();

      expect(find.text('page:/second'), findsOneWidget);
      expect(find.text('page:/detail'), findsNothing);
      expect(names(), ['/', '/second']);

      await disposeHost(tester, [delegate]);
    });

    testWidgets('offAll leaves only the target page', (tester) async {
      final delegate = RxRouterDelegate();
      await tester.pumpWidget(hostRouter(delegate));
      await tester.pumpAndSettle();

      unawaited(router.to('/detail'));
      await tester.pumpAndSettle();

      unawaited(router.offAll('/second'));
      await tester.pumpAndSettle();

      expect(find.text('page:/second'), findsOneWidget);
      expect(find.text('page:/detail'), findsNothing);
      expect(names(), ['/second']);

      await disposeHost(tester, [delegate]);
    });

    testWidgets('a system pop is synced back into the global stack',
        (tester) async {
      final delegate = RxRouterDelegate();
      await tester.pumpWidget(hostRouter(delegate));
      await tester.pumpAndSettle();

      final pending = router.to<String>('/detail');
      await tester.pumpAndSettle();

      // 模拟系统返回键 / 手势返回。
      final handled = await delegate.popRoute();
      await tester.pumpAndSettle();

      expect(handled, isTrue);
      expect(names(), ['/']);
      expect(find.text('page:/'), findsOneWidget);
      // onDidRemovePage -> back()，等待结果的 Future 应该以 null 完成。
      expect(await pending, isNull);

      await disposeHost(tester, [delegate]);
    });

    testWidgets('a system pop on the last page is not handled', (tester) async {
      final delegate = RxRouterDelegate();
      await tester.pumpWidget(hostRouter(delegate));
      await tester.pumpAndSettle();

      final handled = await delegate.popRoute();
      await tester.pumpAndSettle();

      expect(handled, isFalse);
      expect(names(), ['/']);

      await disposeHost(tester, [delegate]);
    });
  });

  group('root delegate is not hijacked by tab stacks (regression)', () {
    testWidgets('initTabIfNeeded does not replace the visible page',
        (tester) async {
      final delegate = RxRouterDelegate();
      await tester.pumpWidget(hostRouter(delegate));
      await tester.pumpAndSettle();

      router.initTabIfNeeded(0, [testPage('/detail', 'tab0_root')]);
      await tester.pumpAndSettle();

      // 修复前：根 Navigator 会改为渲染 tab0 的栈，这里会变成 page:/detail。
      expect(find.text('page:/'), findsOneWidget);
      expect(find.text('page:/detail'), findsNothing);

      await disposeHost(tester, [delegate]);
    });

    testWidgets('initTab does not replace the visible page', (tester) async {
      final delegate = RxRouterDelegate();
      await tester.pumpWidget(hostRouter(delegate));
      await tester.pumpAndSettle();

      router.initTab(0, [testPage('/detail', 'tab0_root')]);
      await tester.pumpAndSettle();

      expect(find.text('page:/'), findsOneWidget);
      expect(find.text('page:/detail'), findsNothing);

      await disposeHost(tester, [delegate]);
    });

    testWidgets('switching tabs does not change the visible page',
        (tester) async {
      router.initTab(0, [testPage('/tab-a', 'tab0_root')]);
      router.initTab(1, [testPage('/tab-b', 'tab1_root')]);
      final delegate = RxRouterDelegate();
      await tester.pumpWidget(hostRouter(delegate));
      await tester.pumpAndSettle();

      router.switchTab(1);
      await tester.pumpAndSettle();

      expect(find.text('page:/'), findsOneWidget);
      expect(find.text('page:/tab-a'), findsNothing);
      expect(find.text('page:/tab-b'), findsNothing);

      await disposeHost(tester, [delegate]);
    });

    testWidgets('pushing inside a tab does not touch the root navigator',
        (tester) async {
      router.initTab(0, [testPage('/tab-a', 'tab0_root')]);
      final delegate = RxRouterDelegate();
      await tester.pumpWidget(hostRouter(delegate));
      await tester.pumpAndSettle();

      unawaited(router.to('/detail'));
      await tester.pumpAndSettle();

      // 页面进入了 tab0 的栈，根 Navigator 不渲染它。
      expect(namesOf(router.tabPages[0]!.value), ['/tab-a', '/detail']);
      expect(names(), ['/']);
      expect(find.text('page:/detail'), findsNothing);
      expect(find.text('page:/'), findsOneWidget);

      await disposeHost(tester, [delegate]);
    });
  });

  group('custom stack delegates', () {
    testWidgets('each delegate renders its own stack side by side',
        (tester) async {
      router.initTab(0, [testPage('/tab-a', 'tab0_root')]);
      router.initTab(1, [testPage('/tab-b', 'tab1_root')]);

      final first = KeyedRxRouterDelegate(customStack: router.tabPages[0]);
      final second = KeyedRxRouterDelegate(customStack: router.tabPages[1]);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Expanded(child: Router<Object>(routerDelegate: first)),
              Expanded(child: Router<Object>(routerDelegate: second)),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 全局栈里的 "/" 页面不应该出现。
      expect(find.text('page:/tab-a'), findsOneWidget);
      expect(find.text('page:/tab-b'), findsOneWidget);
      expect(find.text('page:/'), findsNothing);

      await disposeHost(tester, [first, second]);
    });

    testWidgets('a delegate re-renders when its own stack changes',
        (tester) async {
      router.initTab(0, [testPage('/tab-a', 'tab0_root')]);
      router.initTab(1, [testPage('/tab-b', 'tab1_root')]);

      final first = KeyedRxRouterDelegate(customStack: router.tabPages[0]);
      final second = KeyedRxRouterDelegate(customStack: router.tabPages[1]);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Expanded(child: Router<Object>(routerDelegate: first)),
              Expanded(child: Router<Object>(routerDelegate: second)),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.tabPages[0]!.value = [
        ...router.tabPages[0]!.value,
        testPage('/detail', 'tab0_detail'),
      ];
      await tester.pumpAndSettle();

      expect(find.text('page:/detail'), findsOneWidget);
      expect(find.text('page:/tab-b'), findsOneWidget);

      await disposeHost(tester, [first, second]);
    });
  });
}
