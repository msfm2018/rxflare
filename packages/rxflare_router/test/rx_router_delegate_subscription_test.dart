import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_router/rxflare_router.dart';

void main() {
  group('RxRouterDelegate subscription reproduction', () {
    test('should notify when active tab changes', () {
      final router = RxRouter.I;

      // 先准备两个 Tab 页面栈，再创建 Delegate。
      router.initTab(101, []);
      router.initTab(102, []);

      final delegate = RxRouterDelegate();

      var notifyCount = 0;
      delegate.addListener(() {
        notifyCount++;
      });

      // 切换 Tab。
      router.switchTab(102);
      // ignore: avoid_print
      print('切换 Tab 后 Delegate 通知次数: $notifyCount');

      // 期望切换 Tab 时通知 Delegate。
      expect(notifyCount, 1);

      delegate.dispose();
    });

    test('should notify when a tab stack is created after delegate', () {
      final router = RxRouter.I;

      // 先创建 Delegate，此时还没有 103 这个 Tab。
      final delegate = RxRouterDelegate();

      var notifyCount = 0;
      delegate.addListener(() {
        notifyCount++;
      });

      // Delegate 创建之后，才创建新的 Tab 栈。
      // Delegate 创建之后，才创建新的 Tab 栈。
      router.initTab(103, []);
      // ignore: avoid_print
      print('新增 Tab 后 Delegate 通知次数: $notifyCount');

// 新增 Tab 栈应该通知一次。
      expect(notifyCount, 1);

// 修改新 Tab 的页面栈。
      router.tabPages[103]!.value = [
        RxPage(
          name: '/late-tab',
          pageId: 'late-tab-page',
          params: {},
          query: {},
        ),
      ];
      // ignore: avoid_print
      print('修改新 Tab 页面栈后通知次数: $notifyCount');

// 新 Tab 页面栈也应该已经成功绑定。
      expect(notifyCount, 2);

      delegate.dispose();
    });
  });
}
