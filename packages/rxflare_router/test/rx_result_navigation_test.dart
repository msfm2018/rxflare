import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:rxflare_router/rxflare_router.dart';

void main() {
  final router = RxRouter.I;

  setUp(() {
    router.memPages.value = [];
    router.tabPages.clear();
    router.activeTabIndex.value = 0;

    router.register({
      '/detail': RxRoute(
        builder: () => const SizedBox(),
      ),
      '/replacement': RxRoute(
        builder: () => const SizedBox(),
      ),
      '/home': RxRoute(
        builder: () => const SizedBox(),
      ),
    });

    router.ensureInitialized();
  });

  group('RxResult navigation reproduction', () {
    test('off should complete the removed page Future', () async {
      final detailFuture = router.to<int>('/detail');

      final replacementFuture = router.off<void>('/replacement');

      // 旧页面被 off 移除后，Future 应该返回 null。
      final result = await detailFuture.timeout(
        const Duration(milliseconds: 100),
        onTimeout: () => -1,
      );
      // ignore: avoid_print
      print('off 移除页面后的 Future 结果: $result');

      expect(result, isNull);

      // 清理新页面对应的等待结果。
      router.back<void>();
      await replacementFuture;
    });

    test('offAll should complete all removed page Futures', () async {
      final detailFuture = router.to<int>('/detail');

      final homeFuture = router.offAll<void>('/home');

      // detail 页面被 offAll 移除，Future 应该返回 null。
      final result = await detailFuture.timeout(
        const Duration(milliseconds: 100),
        onTimeout: () => -1,
      );
      // ignore: avoid_print
      print('offAll 移除页面后的 Future 结果: $result');

      expect(result, isNull);

      // offAll 后的新页面没有被移除，手动完成它的 Future。
      final currentPageId = router.pageId()!;
      RxResult.complete(currentPageId, null);

      await homeFuture;
    });
  });
}
