// 这个文件描述的是「期望行为」，目前的 rx_router_core.dart 还不满足，
// 其中带 [已知问题] 标记的用例在修复前会失败。
//
// 原因：RxRouterDelegate.setNewRoutePath 用 `current.name != path` 判断是否需要跳转。
// name 是路由 key（例如 /user），path 是完整地址（例如 /user/42?x=1），
// 所以动态路由和带 query 的地址永远「不相等」，
// 浏览器回退 / 深链接重复通知同一个地址时，会反复压入相同页面。
//
// 建议的修复（把比较对象从 name 改成当前页面对应的地址）：
//
//   @override
//   Future<void> setNewRoutePath(Object configuration) async {
//     final path = configuration.toString();
//     if (currentConfiguration != path) {
//       RxRouter.I.to(path);
//     }
//   }
//
// 修复之后，这个文件里的所有用例都应该通过。

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_router/rxflare_router.dart';

import 'helpers/router_test_utils.dart';

void main() {
  final router = RxRouter.I;

  List<String> names() => namesOf(router.memPages.value);

  setUp(() {
    resetRouter();

    router.register({
      '/': RxRoute(builder: () => const SizedBox()),
      '/home': RxRoute(builder: () => const SizedBox()),
      '/detail': RxRoute(builder: () => const SizedBox()),
      '/user': RxRoute(path: '/user/:id', builder: () => const SizedBox()),
    });
  });

  group('setNewRoutePath', () {
    test('does not push when the location is the current root page', () async {
      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      await delegate.setNewRoutePath('/');

      expect(names(), ['/']);
    });

    test('[已知问题] does not push the same parameterised path twice', () async {
      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      await delegate.setNewRoutePath('/user/42');
      await delegate.setNewRoutePath('/user/42');

      expect(names(), ['/', '/user']);
    });

    test('[已知问题] does not push the same path with a query twice', () async {
      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      await delegate.setNewRoutePath('/detail?id=1');
      await delegate.setNewRoutePath('/detail?id=1');

      expect(names(), ['/', '/detail']);
    });

    test('pushes again when the path parameter changes', () async {
      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      await delegate.setNewRoutePath('/user/42');
      await delegate.setNewRoutePath('/user/43');

      expect(names(), ['/', '/user', '/user']);
      expect(router.param('id'), '43');
    });

    test('pushes again when only the query changes', () async {
      final delegate = RxRouterDelegate();
      addTearDown(delegate.dispose);

      await delegate.setNewRoutePath('/detail?id=1');
      await delegate.setNewRoutePath('/detail?id=2');

      expect(names(), ['/', '/detail', '/detail']);
      expect(router.queryItem('id'), '2');
    });
  });
}
