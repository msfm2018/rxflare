import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_router/rxflare_router.dart';

import 'helpers/router_test_utils.dart';

/// 与 demo 里的 MainTabWrapper 相同的结构：
/// 全局栈里的 "/home" 页面 = 带底部导航栏的外壳，
/// 每个 Tab 内部是一个由 customStack 驱动的嵌套 Router。
class _TabShell extends StatefulWidget {
  const _TabShell();

  @override
  State<_TabShell> createState() => _TabShellState();
}

class _TabShellState extends State<_TabShell> {
  KeyedRxRouterDelegate? _homeDelegate;
  KeyedRxRouterDelegate? _meDelegate;
  int _index = 0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();

    // 在构建完成后再初始化 Tab 栈，避免在 build 期间触发 setState。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final r = RxRouter.I;
      r.initTabIfNeeded(0, [RxPage(name: '/tab0', pageId: 'tab0_root')]);
      r.initTabIfNeeded(1, [RxPage(name: '/tab1', pageId: 'tab1_root')]);

      setState(() {
        _homeDelegate = KeyedRxRouterDelegate(customStack: r.tabPages[0]);
        _meDelegate = KeyedRxRouterDelegate(customStack: r.tabPages[1]);
        _index = r.activeTabIndex.value;
        _ready = true;
      });
    });
  }

  @override
  void dispose() {
    _homeDelegate?.dispose();
    _meDelegate?.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (index == _index) return;
    RxRouter.I.switchTab(index);
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !_ready
          ? const SizedBox.shrink()
          : IndexedStack(
              index: _index,
              children: [
                Router<Object>(routerDelegate: _homeDelegate!),
                Router<Object>(routerDelegate: _meDelegate!),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _switchTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }
}

void main() {
  final router = RxRouter.I;

  setUp(() {
    resetRouter();

    router.register({
      '/': RxRoute(builder: () => const Text('launcher')),
      '/home': RxRoute(builder: () => const _TabShell()),
      '/tab0': RxRoute(builder: () => const Text('tab0 root')),
      '/tab1': RxRoute(builder: () => const Text('tab1 root')),
      '/detail': RxRoute(builder: () => const Text('detail page')),
      '/user': RxRoute(
        path: '/user/:id',
        builder: () => const Text('user page'),
      ),
    });

    router.ensureInitialized();
  });

  /// 渲染根 Delegate，并像真实应用一样从启动页跳到带底部栏的外壳。
  Future<RxRouterDelegate> openShell(WidgetTester tester) async {
    final root = RxRouterDelegate();

    await tester.pumpWidget(hostRouter(root));
    await tester.pumpAndSettle();
    expect(find.text('launcher'), findsOneWidget);

    unawaited(router.to('/home'));
    await tester.pumpAndSettle();

    return root;
  }

  group('bottom navigation shell', () {
    testWidgets('shows the bottom bar and the first tab (regression)',
        (tester) async {
      final root = await openShell(tester);

      // 修复前：initTabIfNeeded 之后根 Navigator 改为渲染 tab0 的栈，
      // 外壳被整体替换，底部栏消失。
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Me'), findsOneWidget);
      expect(find.text('tab0 root'), findsOneWidget);

      // 全局栈仍然是 [启动页, 外壳]，没有被 tab 栈改写。
      expect(namesOf(router.memPages.value), ['/', '/home']);

      await disposeHost(tester, [root]);
    });

    testWidgets('creates one stack per tab', (tester) async {
      final root = await openShell(tester);

      expect(router.tabPages.keys.toSet(), {0, 1});
      expect(namesOf(router.tabPages[0]!.value), ['/tab0']);
      expect(namesOf(router.tabPages[1]!.value), ['/tab1']);

      await disposeHost(tester, [root]);
    });

    testWidgets('tapping a tab shows its page and keeps the bar',
        (tester) async {
      final root = await openShell(tester);

      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();

      expect(router.activeTabIndex.value, 1);
      expect(find.text('tab1 root'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(router.activeTabIndex.value, 0);
      expect(find.text('tab0 root'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      await disposeHost(tester, [root]);
    });

    testWidgets('pushing a page inside a tab keeps the bottom bar',
        (tester) async {
      final root = await openShell(tester);

      unawaited(router.to('/detail'));
      await tester.pumpAndSettle();

      expect(find.text('detail page'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(namesOf(router.tabPages[0]!.value), ['/tab0', '/detail']);
      expect(namesOf(router.memPages.value), ['/', '/home']);

      await disposeHost(tester, [root]);
    });

    testWidgets('back inside a tab pops the page and keeps the bar',
        (tester) async {
      final root = await openShell(tester);
      final pending = router.to<String>('/detail');
      await tester.pumpAndSettle();

      router.back(result: 'result from detail');
      await tester.pumpAndSettle();

      expect(find.text('detail page'), findsNothing);
      expect(find.text('tab0 root'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(await pending, 'result from detail');

      await disposeHost(tester, [root]);
    });

    testWidgets('back at a tab root does not close the shell', (tester) async {
      final root = await openShell(tester);

      router.back();
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('tab0 root'), findsOneWidget);
      expect(namesOf(router.memPages.value), ['/', '/home']);

      await disposeHost(tester, [root]);
    });

    testWidgets('each tab keeps its own history across tab switches',
        (tester) async {
      final root = await openShell(tester);

      // Home tab：压入 detail。
      unawaited(router.to('/detail'));
      await tester.pumpAndSettle();

      // 切到 Me tab：此时 to 进入 Me 的栈。
      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();
      unawaited(router.to('/user/1'));
      await tester.pumpAndSettle();

      expect(find.text('user page'), findsOneWidget);
      expect(namesOf(router.tabPages[0]!.value), ['/tab0', '/detail']);
      expect(namesOf(router.tabPages[1]!.value), ['/tab1', '/user']);

      // 回到 Home tab：detail 还在。
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.text('detail page'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      await disposeHost(tester, [root]);
    });

    testWidgets('disposing the shell unbinds its tab delegates',
        (tester) async {
      final root = await openShell(tester);

      await disposeHost(tester, [root]);

      // 外壳和根 Delegate 都已释放；再修改栈不应该触发任何已释放对象的通知。
      expect(() {
        router.tabPages[0]!.value = [
          RxPage(name: '/tab0', pageId: 'tab0_again'),
        ];
        router.memPages.value = [RxPage(name: '/', pageId: 'g_again')];
        router.switchTab(1);
      }, returnsNormally);
    });
  });
}
