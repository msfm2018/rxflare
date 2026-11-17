import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_router/rxflare_router.dart';

void main() {
  testWidgets(
    'RxWidgetsApp should reuse RouterDelegate across rebuilds',
    (tester) async {
      final router = RxRouter.I;

      router.memPages.value = [];
      router.initialRoute = '/';

      late VoidCallback rebuild;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuild = () {
                setState(() {});
              };

              return RxWidgetsApp(
                routes: {
                  '/': RxRoute(
                    builder: () => const SizedBox(),
                  ),
                  '/detail': RxRoute(
                    builder: () => const SizedBox(),
                  ),
                },
              );
            },
          ),
        ),
      );

      Router<Object> getRouterWidget() {
        return tester.widget<Router<Object>>(
          find.byType(Router<Object>),
        );
      }

      final firstDelegate =
          getRouterWidget().routerDelegate as RxRouterDelegate;

      // 强制 RxWidgetsApp 重建。
      rebuild();
      await tester.pump();

      final secondDelegate =
          getRouterWidget().routerDelegate as RxRouterDelegate;

      expect(
        identical(firstDelegate, secondDelegate),
        isTrue,
        reason: 'RxWidgetsApp should reuse the same RouterDelegate.',
      );

      await tester.pumpWidget(const SizedBox());

      router.memPages.value = [];
    },
  );
}
