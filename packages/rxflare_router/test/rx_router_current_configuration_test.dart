import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:rxflare_router/rxflare_router.dart';

void main() {
  test('currentConfiguration should encode path and query parameters', () {
    final router = RxRouter.I;

    router.register({
      '/detail': RxRoute(
        path: '/detail/:id',
        builder: () => const SizedBox(),
      ),
    });

    router.memPages.value = [
      RxPage(
        name: '/detail',
        pageId: 'test_page_2',
        params: {
          'id': 'hello world',
        },
        query: {
          'keyword': 'hello world',
        },
      ),
    ];

    final delegate = RxRouterDelegate();

    expect(
      delegate.currentConfiguration,
      '/detail/hello%20world?keyword=hello+world',
    );

    delegate.dispose();
    router.memPages.value = [];
  });

  test('currentConfiguration should restore path and query parameters', () {
    final router = RxRouter.I;

    router.register({
      '/detail': RxRoute(
        path: '/detail/:id',
        builder: () => const SizedBox(),
      ),
    });

    router.memPages.value = [
      RxPage(
        name: '/detail',
        pageId: 'test_page_1',
        params: {
          'id': '123',
        },
        query: {
          'tab': 'profile',
          'source': 'home',
        },
      ),
    ];

    final delegate = RxRouterDelegate();

    expect(
      delegate.currentConfiguration,
      '/detail/123?tab=profile&source=home',
    );

    delegate.dispose();
    router.memPages.value = [];
  });
}
