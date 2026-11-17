// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_router/rxflare_router.dart';

/// 重置 RxRouter 单例的全部可变状态。
///
/// RxRouter 是单例，同一个测试文件里的用例会共享状态，
/// 所以每个用例的 setUp 都应该先调用它。
void resetRouter() {
  final router = RxRouter.I;
  router.memPages.value = [];
  router.tabPages.clear();
  router.activeTabIndex.value = 0;
  router.initialRoute = '/';
}

/// 快速构造一个 [RxPage]。
RxPage testPage(
  String name,
  String pageId, {
  Map<String, String> params = const {},
  Map<String, String> query = const {},
}) {
  return RxPage(name: name, pageId: pageId, params: params, query: query);
}

/// 取出栈里所有页面的 name，方便断言。
List<String> namesOf(List<RxPage> stack) {
  return stack.map((p) => p.name).toList();
}

/// 让 microtask / 零延迟 Timer 跑完，用于等待异步守卫。
///
/// 只能在普通 `test()` 里使用。
/// `testWidgets` 里请使用 `tester.pump()` / `tester.pumpAndSettle()`。
Future<void> flushAsync() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// 注册一组路由，每个页面渲染 `Text('page:<name>')`。
void registerTextRoutes(Iterable<String> names) {
  RxRouter.I.register({
    for (final name in names) name: RxRoute(builder: () => Text('page:$name')),
  });
}

/// 每个实例拥有独立 navigatorKey 的 Delegate。
///
/// 默认的 [RxRouterDelegate] 共用 `RxRouter.I.navigatorKey`，
/// 同一棵树里放多个 Navigator 会触发 GlobalKey 冲突。
/// 底部 Tab 的每个 Tab 都需要自己的 Key。
class KeyedRxRouterDelegate extends RxRouterDelegate {
  KeyedRxRouterDelegate({super.customStack});

  final GlobalKey<NavigatorState> _key = GlobalKey<NavigatorState>();

  @override
  GlobalKey<NavigatorState> get navigatorKey => _key;
}

/// 把一个根 Delegate 放进 MaterialApp。
///
/// 不使用 MaterialApp.router，这样不会触发平台的初始路由（"/"）
/// 和 setNewRoutePath，测试更可控。
Widget hostRouter(RxRouterDelegate delegate) {
  return MaterialApp(
    home: Router<Object>(routerDelegate: delegate),
  );
}

/// 先卸载 Widget 树，再释放 Delegate。
///
/// 顺序不能反：Router 在 dispose 时会调用 delegate.removeListener，
/// 如果 Delegate 已经 dispose，debug 模式下会断言失败。
Future<void> disposeHost(
  WidgetTester tester,
  List<RxRouterDelegate> delegates,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (final delegate in delegates) {
    delegate.dispose();
  }
}
