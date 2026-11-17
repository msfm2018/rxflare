import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_router/rxflare_router.dart';

import 'helpers/router_test_utils.dart';

/// 记录自己被创建了几次，用来验证页面状态有没有被保留。
class _LifecycleProbe extends StatefulWidget {
  const _LifecycleProbe({required this.label, required this.onInit});

  final String label;
  final VoidCallback onInit;

  @override
  State<_LifecycleProbe> createState() => _LifecycleProbeState();
}

class _LifecycleProbeState extends State<_LifecycleProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => Text(widget.label);
}

void main() {
  final router = RxRouter.I;

  List<String> names() => namesOf(router.memPages.value);

  setUp(() {
    resetRouter();
    registerTextRoutes(['/', '/detail', '/second', '/tab-a', '/tab-b']);
    router.ensureInitialized();
  });

  group('RxPageRoute', () {
    testWidgets('createRoute builds a PageRouteBuilder bound to the page',
        (tester) async {
      const page = RxPageRoute(
        child: Text('child'),
        name: 'page-name',
        arguments: 'page-args',
      );
      late Route<dynamic> route;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            route = page.createRoute(context);
            return const SizedBox();
          },
        ),
      );

      expect(route, isA<PageRouteBuilder<dynamic>>());
      expect(route.settings, same(page));
      expect(route.settings.name, 'page-name');
      expect(route.settings.arguments, 'page-args');
    });

    testWidgets('pages fade in while they are being pushed', (tester) async {
      final delegate = RxRouterDelegate();
      await tester.pumpWidget(hostRouter(delegate));
      await tester.pumpAndSettle();

      unawaited(router.to('/detail'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));

      final fades = tester.widgetList<FadeTransition>(
        find.ancestor(
          of: find.text('page:/detail'),
          matching: find.byType(FadeTransition),
        ),
      );

      // 转场进行到一半时，至少有一层 FadeTransition 处于半透明状态。
      expect(
        fades.any((f) => f.opacity.value > 0 && f.opacity.value < 1),
        isTrue,
      );

      await tester.pumpAndSettle();
      await disposeHost(tester, [delegate]);
    });
  });

  group('page state', () {
    testWidgets('an existing page keeps its state while others come and go',
        (tester) async {
      var rootInits = 0;
      router.register({
        '/': RxRoute(
          builder: () => _LifecycleProbe(
            label: 'root probe',
            onInit: () => rootInits++,
          ),
        ),
      });
      final delegate = RxRouterDelegate();
      await tester.pumpWidget(hostRouter(delegate));
      await tester.pumpAndSettle();
      expect(rootInits, 1);

      unawaited(router.to('/detail'));
      await tester.pumpAndSettle();
      unawaited(router.to('/second'));
      await tester.pumpAndSettle();
      router.back();
      await tester.pumpAndSettle();
      router.back();
      await tester.pumpAndSettle();

      // delegate 每次重建都会重新调用 builder，
      // 但根页面的 State 不应该被重新创建。
      expect(find.text('root probe'), findsOneWidget);
      expect(rootInits, 1);

      await disposeHost(tester, [delegate]);
    });

    testWidgets('the same route pushed twice creates two independent pages',
        (tester) async {
      var inits = 0;
      router.register({
        '/probe': RxRoute(
          builder: () => _LifecycleProbe(
            label: 'probe',
            onInit: () => inits++,
          ),
        ),
      });
      final delegate = RxRouterDelegate();
      await tester.pumpWidget(hostRouter(delegate));
      await tester.pumpAndSettle();

      unawaited(router.to('/probe'));
      await tester.pumpAndSettle();
      unawaited(router.to('/probe'));
      await tester.pumpAndSettle();

      expect(inits, 2);
      expect(
        find.byType(_LifecycleProbe, skipOffstage: false),
        findsNWidgets(2),
      );
      expect(names(), ['/', '/probe', '/probe']);

      await disposeHost(tester, [delegate]);
    });
  });

  group('route registration', () {
    testWidgets('registering a key again replaces its builder', (tester) async {
      router.register({'/swap': RxRoute(builder: () => const Text('v1'))});
      router.register({'/swap': RxRoute(builder: () => const Text('v2'))});
      final delegate = RxRouterDelegate();
      await tester.pumpWidget(hostRouter(delegate));
      await tester.pumpAndSettle();

      unawaited(router.to('/swap'));
      await tester.pumpAndSettle();

      expect(find.text('v2'), findsOneWidget);
      expect(find.text('v1'), findsNothing);

      await disposeHost(tester, [delegate]);
    });
  });

  group('system back', () {
    testWidgets('clears the arguments of the popped page', (tester) async {
      final delegate = RxRouterDelegate();
      await tester.pumpWidget(hostRouter(delegate));
      await tester.pumpAndSettle();

      unawaited(router.to('/detail', arguments: 'payload'));
      await tester.pumpAndSettle();
      final pageId = router.pageId()!;
      expect(RxArgs.I.get<String>(pageId), 'payload');

      await delegate.popRoute();
      await tester.pumpAndSettle();

      expect(RxArgs.I.get<String>(pageId), isNull);
      expect(names(), ['/']);

      await disposeHost(tester, [delegate]);
    });

    testWidgets('a tab delegate pops only its own tab stack', (tester) async {
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

      // 当前激活的是 tab0，所以 detail 进入 tab0 的栈。
      unawaited(router.to('/detail'));
      await tester.pumpAndSettle();
      expect(find.text('page:/detail'), findsOneWidget);

      final handled = await first.popRoute();
      await tester.pumpAndSettle();

      expect(handled, isTrue);
      expect(namesOf(router.tabPages[0]!.value), ['/tab-a']);
      expect(namesOf(router.tabPages[1]!.value), ['/tab-b']);
      expect(names(), ['/']);
      expect(find.text('page:/detail'), findsNothing);

      await disposeHost(tester, [first, second]);
    });
  });
}
