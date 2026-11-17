import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_core/rxflare_core.dart';

void main() {
  test('RxEffect should reconcile dependencies when callback throws', () async {
    final selector = 0.rx;
    final oldDep = 0.rx;
    final newDep = 0.rx;

    var runs = 0;
    var shouldThrow = true;

    final errorCaught = Completer<Object>();

    late void Function() stop;

    runZonedGuarded(() {
      stop = effect(() {
        runs++;

        if (selector.value == 0) {
          // 第一次执行：依赖 oldDep。
          if (oldDep.value == -1) {
            // ignore: avoid_print
            print('unreachable');
          }
        } else {
          // 第二次执行：依赖 newDep。
          if (newDep.value == -1) {
            // ignore: avoid_print
            print('unreachable');
          }

          if (shouldThrow) {
            shouldThrow = false;
            throw StateError('Test callback error');
          }
        }
      });

      // 触发第二次执行。
      selector.value = 1;
    }, (error, stack) {
      if (!errorCaught.isCompleted) {
        errorCaught.complete(error);
      }
    });

    // 等待 callback 抛出异常。
    final error = await errorCaught.future;

    expect(error, isA<StateError>());
    expect(runs, 2);

    // 修改新依赖，应该触发 Effect。
    newDep.value = 1;
    await Future<void>.delayed(Duration.zero);

    expect(
      runs,
      3,
      reason:
          'Effect should subscribe to new dependencies even when callback throws.',
    );

    // 修改旧依赖，不应该再触发 Effect。
    oldDep.value = 1;
    await Future<void>.delayed(Duration.zero);

    expect(
      runs,
      3,
      reason: 'Effect should unsubscribe from obsolete dependencies.',
    );

    stop();
  });
}
