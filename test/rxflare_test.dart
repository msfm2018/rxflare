import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare/rxflare.dart';

void main() {
  group('RxState', () {
    test('emits current value and updates on mutation', () {
      final state = RxState<int>(1);
      final values = <int>[];

      final cancel = state.listen((value) {
        values.add(value);
      });

      state.value = 2;
      cancel();

      expect(values, [1, 2]);
    });

    test('supports field-level updates for maps', () {
      final user = RxState<Map<String, dynamic>>({
        'name': 'Tom',
        'age': 25,
      });

      final seen = <dynamic>[];
      final cancel = user.listenByKey('name', (value) {
        seen.add(value);
      });

      user.updateField('name', 'Jerry');
      user.updateField('age', 30);
      cancel();

      expect(seen, ['Tom', 'Jerry']);
    });
  });

  group('RxComputed', () {
    test('recomputes when dependencies change', () {
      final a = RxState<int>(2);
      final b = RxState<int>(3);
      final total = computed(() => a.value + b.value);

      expect(total.value, 5);

      a.value = 4;
      expect(total.value, 7);

      b.value = 10;
      expect(total.value, 14);
    });
  });

  group('RxEventBus', () {
    test('delivers events to subscribers', () async {
      final completer = Completer<String>();

      RxEventBus.on<String>(
        module: 'test',
        eventID: 1,
        callback: (eventID, uuid, data) async {
          completer.complete(data);
        },
      );

      RxEventBus.notify<String>(
        module: 'test',
        eventID: 1,
        data: 'hello',
      );

      expect(await completer.future.timeout(const Duration(seconds: 1)), 'hello');
      RxEventBus.off(module: 'test', eventID: 1);
    });

    test('supports token-based cleanup', () {
      final token = EventToken();
      var count = 0;

      RxEventBus.on<String>(
        module: 'cleanup',
        eventID: 2,
        token: token,
        callback: (eventID, uuid, data) async {
          count++;
        },
      );

      RxEventBus.notify<String>(
        module: 'cleanup',
        eventID: 2,
        data: 'first',
      );

      RxEventBus.offByToken(token);
      RxEventBus.notify<String>(
        module: 'cleanup',
        eventID: 2,
        data: 'second',
      );

      expect(count, 1);
      RxEventBus.clearAll();
    });
  });
}
