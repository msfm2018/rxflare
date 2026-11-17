// 用一个「假的浏览器地址栏」模拟 Web 行为，在普通 `flutter test` 里就能运行：
//
//  - 路由器有没有把新地址上报给地址栏（对应真实浏览器的 URL 变化）
//  - 打开深链接（初始地址不是 "/"）时的行为
//  - 用户在地址栏输入新地址 / 点击浏览器后退时的行为
//
// 这里模拟的是 Flutter 的 RouteInformationProvider 接口，
// 并不会真的调用浏览器的 History API。

import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_router/rxflare_router.dart';

import 'helpers/router_test_utils.dart';

// 浏览器后退目前会「压入」上一个地址而不是「弹出」当前页面。
// 修复思路：setNewRoutePath 先判断目标地址是否等于栈中倒数第二个页面对应的地址，
// 如果是，就说明是浏览器后退，应当调用 back() 而不是 to()。
// 修复后把它改成 null 即可启用该用例。

/// 模拟浏览器地址栏。

/// 模拟浏览器地址栏及 History 历史记录。
class FakeBrowserProvider extends RouteInformationProvider with ChangeNotifier {
  FakeBrowserProvider(String initialLocation)
      : _value = RouteInformation(uri: Uri.parse(initialLocation)) {
    history.add(_value);
  }

  RouteInformation _value;

  /// Router 上报的地址。
  final List<RouteInformation> reported = [];

  /// 模拟浏览器 History。
  final List<RouteInformation> history = [];

  /// 当前历史记录的位置。
  int historyIndex = 0;

  @override
  RouteInformation get value => _value;

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    reported.add(routeInformation);

    final sameLocation = _value.uri == routeInformation.uri;
    _value = routeInformation;

    // 地址没有变化，不创建重复历史记录。
    if (sameLocation) return;

    if (type == RouteInformationReportingType.neglect) {
      // neglect：替换当前历史记录，不新增历史条目。
      if (history.isEmpty) {
        history.add(routeInformation);
        historyIndex = 0;
      } else {
        history[historyIndex] = routeInformation;
      }
      return;
    }

    // navigate 和 none 在这个测试模拟器中均视为新导航。
    // 删除前进记录。
    if (historyIndex < history.length - 1) {
      history.removeRange(historyIndex + 1, history.length);
    }

    history.add(routeInformation);
    historyIndex = history.length - 1;
  }

  /// 模拟用户在地址栏输入地址。
  void browserNavigate(String location) {
    final info = RouteInformation(uri: Uri.parse(location));

    if (historyIndex < history.length - 1) {
      history.removeRange(historyIndex + 1, history.length);
    }

    history.add(info);
    historyIndex = history.length - 1;
    _value = info;

    notifyListeners();
  }

  /// 模拟浏览器后退。
  void browserBack() {
    if (historyIndex <= 0) return;

    historyIndex--;
    _value = history[historyIndex];

    notifyListeners();
  }

  /// 模拟浏览器前进。
  void browserForward() {
    if (historyIndex >= history.length - 1) return;

    historyIndex++;
    _value = history[historyIndex];

    notifyListeners();
  }

  String? get lastReported =>
      reported.isEmpty ? null : reported.last.uri.toString();

  String get currentLocation => _value.uri.toString();
}

void main() {
  final router = RxRouter.I;
  final parser = RxRouteParser();

  List<String> names() => namesOf(router.memPages.value);

  setUp(() {
    resetRouter();

    router.register({
      '/': RxRoute(builder: () => const Text('page:/')),
      '/detail': RxRoute(builder: () => const Text('page:/detail')),
      '/user': RxRoute(
        path: '/user/:id',
        builder: () => Text('user:${router.param('id')}'),
      ),
      '/blocked': RxRoute(
        builder: () => const Text('page:/blocked'),
        guard: () async => false,
      ),
    });

    router.ensureInitialized();
  });

  Future<void> pumpApp(
    WidgetTester tester,
    RxRouterDelegate delegate,
    FakeBrowserProvider browser,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerDelegate: delegate,
        routeInformationParser: parser,
        routeInformationProvider: browser,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> disposeApp(
    WidgetTester tester,
    RxRouterDelegate delegate,
    FakeBrowserProvider browser,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    delegate.dispose();
    browser.dispose();
  }

  group('address bar sync', () {
    testWidgets('reports the new location after pushing a page',
        (tester) async {
      final browser = FakeBrowserProvider('/');
      final delegate = RxRouterDelegate();
      await pumpApp(tester, delegate, browser);

      unawaited(router.to('/detail?id=1'));
      await tester.pumpAndSettle();

      expect(browser.lastReported, '/detail?id=1');

      await disposeApp(tester, delegate, browser);
    });

    testWidgets('reports the concrete path of a dynamic route', (tester) async {
      final browser = FakeBrowserProvider('/');
      final delegate = RxRouterDelegate();
      await pumpApp(tester, delegate, browser);

      unawaited(router.to('/user/42'));
      await tester.pumpAndSettle();

      expect(browser.lastReported, '/user/42');

      await disposeApp(tester, delegate, browser);
    });

    testWidgets('reports the previous location after back', (tester) async {
      final browser = FakeBrowserProvider('/');
      final delegate = RxRouterDelegate();
      await pumpApp(tester, delegate, browser);

      unawaited(router.to('/detail'));
      await tester.pumpAndSettle();
      expect(browser.lastReported, '/detail');

      router.back();
      await tester.pumpAndSettle();

      expect(browser.lastReported, '/');

      await disposeApp(tester, delegate, browser);
    });
  });

  testWidgets('browser back pops the current page', (tester) async {
    final browser = FakeBrowserProvider('/');
    final delegate = RxRouterDelegate();

    await pumpApp(tester, delegate, browser);

    unawaited(router.to('/detail'));
    await tester.pumpAndSettle();

    expect(names(), ['/', '/detail']);

// 确认内部导航确实生成了浏览器历史记录。
    expect(
      browser.history.map((e) => e.uri.toString()).toList(),
      ['/', '/detail'],
    );

    expect(browser.historyIndex, 1);

    browser.browserBack();

    expect(browser.currentLocation, '/');
    expect(browser.historyIndex, 0);

    await tester.pumpAndSettle();

    expect(names(), ['/']);

    await tester.pumpAndSettle();

    expect(names(), ['/']);
    expect(find.text('page:/'), findsOneWidget);
    expect(browser.currentLocation, '/');

    await disposeApp(tester, delegate, browser);
  });

  testWidgets('browser forward restores the previous page', (tester) async {
    final browser = FakeBrowserProvider('/');
    final delegate = RxRouterDelegate();

    await pumpApp(tester, delegate, browser);

    unawaited(router.to('/detail'));
    await tester.pumpAndSettle();

    browser.browserBack();
    await tester.pumpAndSettle();

    expect(names(), ['/']);

    browser.browserForward();
    await tester.pumpAndSettle();

    expect(names(), ['/', '/detail']);
    expect(find.text('page:/detail'), findsOneWidget);

    await disposeApp(tester, delegate, browser);
  });

  testWidgets('multiple browser backs pop multiple pages', (tester) async {
    final browser = FakeBrowserProvider('/');
    final delegate = RxRouterDelegate();

    await pumpApp(tester, delegate, browser);

    unawaited(router.to('/detail'));
    await tester.pumpAndSettle();

    unawaited(router.to('/user/42'));
    await tester.pumpAndSettle();

    expect(names(), ['/', '/detail', '/user']);

    browser.browserBack();
    await tester.pumpAndSettle();

    expect(names(), ['/', '/detail']);

    browser.browserBack();
    await tester.pumpAndSettle();

    expect(names(), ['/']);

    await disposeApp(tester, delegate, browser);
  });

  group('navigation operations', () {
    testWidgets('off replaces the current page', (tester) async {
      final browser = FakeBrowserProvider('/');
      final delegate = RxRouterDelegate();

      await pumpApp(tester, delegate, browser);

      unawaited(router.to('/detail'));
      await tester.pumpAndSettle();

      expect(names(), ['/', '/detail']);

      unawaited(router.off('/user/42'));
      await tester.pumpAndSettle();

      expect(names(), ['/', '/user']);
      expect(router.param('id'), '42');
      expect(browser.lastReported, '/user/42');

      await disposeApp(tester, delegate, browser);
    });

    testWidgets('offAll clears the entire navigation stack', (tester) async {
      final browser = FakeBrowserProvider('/');
      final delegate = RxRouterDelegate();

      await pumpApp(tester, delegate, browser);

      unawaited(router.to('/detail'));
      await tester.pumpAndSettle();

      unawaited(router.to('/user/42'));
      await tester.pumpAndSettle();

      expect(names(), ['/', '/detail', '/user']);

      unawaited(router.offAll('/detail?id=1'));
      await tester.pumpAndSettle();

      expect(names(), ['/detail']);
      expect(router.queryItem('id'), '1');
      expect(browser.lastReported, '/detail?id=1');

      await disposeApp(tester, delegate, browser);
    });
  });

  group('browser navigation with guards', () {
    testWidgets('guard blocks browser navigation', (tester) async {
      final browser = FakeBrowserProvider('/');
      final delegate = RxRouterDelegate();

      await pumpApp(tester, delegate, browser);

      browser.browserNavigate('/blocked');
      await tester.pumpAndSettle();

      expect(names(), ['/']);
      expect(find.text('page:/'), findsOneWidget);
      expect(find.text('page:/blocked'), findsNothing);

      await disposeApp(tester, delegate, browser);
    });
  });

  group('deep links (initial address)', () {
    testWidgets('"/" does not push a second root page', (tester) async {
      final browser = FakeBrowserProvider('/');
      final delegate = RxRouterDelegate();

      await pumpApp(tester, delegate, browser);

      expect(names(), ['/']);
      expect(find.text('page:/'), findsOneWidget);

      await disposeApp(tester, delegate, browser);
    });

    testWidgets('opens the target page with its path parameter',
        (tester) async {
      final browser = FakeBrowserProvider('/user/42');
      final delegate = RxRouterDelegate();

      await pumpApp(tester, delegate, browser);

      expect(names(), ['/', '/user']);
      expect(router.param('id'), '42');
      expect(find.text('user:42'), findsOneWidget);

      await disposeApp(tester, delegate, browser);
    });

    testWidgets('decodes and re-encodes non-ASCII path parameters',
        (tester) async {
      final browser = FakeBrowserProvider('/user/%E5%8C%97%E4%BA%AC');
      final delegate = RxRouterDelegate();

      await pumpApp(tester, delegate, browser);

      expect(router.param('id'), '北京');
      expect(find.text('user:北京'), findsOneWidget);
      expect(browser.lastReported, '/user/%E5%8C%97%E4%BA%AC');

      await disposeApp(tester, delegate, browser);
    });

    testWidgets('decodes query parameters', (tester) async {
      final browser = FakeBrowserProvider('/detail?keyword=hello+world');
      final delegate = RxRouterDelegate();

      await pumpApp(tester, delegate, browser);

      expect(names(), ['/', '/detail']);
      expect(router.queryItem('keyword'), 'hello world');
      expect(browser.lastReported, '/detail?keyword=hello+world');

      await disposeApp(tester, delegate, browser);
    });

    testWidgets('a guard can block a deep link', (tester) async {
      final browser = FakeBrowserProvider('/blocked');
      final delegate = RxRouterDelegate();

      await pumpApp(tester, delegate, browser);

      expect(names(), ['/']);
      expect(find.text('page:/blocked'), findsNothing);
      expect(find.text('page:/'), findsOneWidget);

      await disposeApp(tester, delegate, browser);
    });

    testWidgets('an unknown deep link leaves the app on the root page',
        (tester) async {
      final browser = FakeBrowserProvider('/does-not-exist');
      final delegate = RxRouterDelegate();

      await pumpApp(tester, delegate, browser);

      expect(names(), ['/']);
      expect(find.text('page:/'), findsOneWidget);

      await disposeApp(tester, delegate, browser);
    });
  });

  group('browser navigation', () {
    testWidgets('typing a new address opens that page', (tester) async {
      final browser = FakeBrowserProvider('/');
      final delegate = RxRouterDelegate();
      await pumpApp(tester, delegate, browser);

      browser.browserNavigate('/detail');
      await tester.pumpAndSettle();

      expect(names(), ['/', '/detail']);
      expect(find.text('page:/detail'), findsOneWidget);

      await disposeApp(tester, delegate, browser);
    });

    testWidgets('navigating to the current address does nothing',
        (tester) async {
      final browser = FakeBrowserProvider('/');
      final delegate = RxRouterDelegate();
      await pumpApp(tester, delegate, browser);

      unawaited(router.to('/detail'));
      await tester.pumpAndSettle();

      browser.browserNavigate('/detail');
      await tester.pumpAndSettle();

      expect(names(), ['/', '/detail']);

      await disposeApp(tester, delegate, browser);
    });
  });

  group('RxRouteParser with encoded locations', () {
    test('round trip keeps percent-encoded paths and "+" in queries', () async {
      const location = '/user/%E5%8C%97%E4%BA%AC?q=a+b';

      final configuration = await parser.parseRouteInformation(
        RouteInformation(uri: Uri.parse(location)),
      );
      final info = parser.restoreRouteInformation(configuration);

      expect(configuration, location);
      expect(info.uri.toString(), location);
    });
  });
}
