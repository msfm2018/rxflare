import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_router/rxflare_router.dart';

void main() {
  group('RxPage', () {
    test('params and query default to empty maps', () {
      final page = RxPage(name: '/home', pageId: 'p1');

      expect(page.name, '/home');
      expect(page.pageId, 'p1');
      expect(page.params, isEmpty);
      expect(page.query, isEmpty);
    });

    test('keeps params and query', () {
      final page = RxPage(
        name: '/detail',
        pageId: 'p2',
        params: {'id': '1'},
        query: {'tab': 'a'},
      );

      expect(page.params, {'id': '1'});
      expect(page.query, {'tab': 'a'});
    });
  });

  group('RxUtils.generateId', () {
    test('uses the rx_id_ prefix', () {
      expect(RxUtils.generateId(), startsWith('rx_id_'));
    });

    test('never repeats', () {
      final ids = <String>{};
      for (var i = 0; i < 1000; i++) {
        ids.add(RxUtils.generateId());
      }

      expect(ids, hasLength(1000));
    });
  });

  group('RxArgs', () {
    test('returns null for an unknown pageId', () {
      expect(RxArgs.I.get<String>('args_unknown'), isNull);
    });

    test('stores and reads a value', () {
      RxArgs.I.set('args_a', 'hello');

      expect(RxArgs.I.get<String>('args_a'), 'hello');

      RxArgs.I.remove('args_a');
    });

    test('stores complex objects', () {
      final value = {'name': 'ZhangSan', 'age': 18};
      RxArgs.I.set('args_b', value);

      expect(RxArgs.I.get<Map>('args_b'), same(value));

      RxArgs.I.remove('args_b');
    });

    test('overwrites the previous value for the same pageId', () {
      RxArgs.I.set('args_c', 1);
      RxArgs.I.set('args_c', 2);

      expect(RxArgs.I.get<int>('args_c'), 2);

      RxArgs.I.remove('args_c');
    });

    test('keeps values of different pages independent', () {
      RxArgs.I.set('args_d1', 'one');
      RxArgs.I.set('args_d2', 'two');

      expect(RxArgs.I.get<String>('args_d1'), 'one');
      expect(RxArgs.I.get<String>('args_d2'), 'two');

      RxArgs.I.remove('args_d1');
      RxArgs.I.remove('args_d2');
    });

    test('remove deletes only the given pageId', () {
      RxArgs.I.set('args_e1', 'one');
      RxArgs.I.set('args_e2', 'two');

      RxArgs.I.remove('args_e1');

      expect(RxArgs.I.get<String>('args_e1'), isNull);
      expect(RxArgs.I.get<String>('args_e2'), 'two');

      RxArgs.I.remove('args_e2');
    });

    test('removing an unknown pageId does not throw', () {
      expect(() => RxArgs.I.remove('args_never_set'), returnsNormally);
    });

    test('reading with the wrong type throws a TypeError', () {
      RxArgs.I.set('args_f', 'text');

      expect(() => RxArgs.I.get<int>('args_f'), throwsA(isA<TypeError>()));

      RxArgs.I.remove('args_f');
    });
  });

  group('RxResult', () {
    const timeout = Duration(milliseconds: 500);

    test('complete delivers the value to the waiting future', () async {
      final future = RxResult.wait<String>('res_a');

      RxResult.complete('res_a', 'done');

      expect(await future.timeout(timeout), 'done');
    });

    test('complete with null delivers null', () async {
      final future = RxResult.wait<String>('res_b');

      RxResult.complete('res_b', null);

      expect(await future.timeout(timeout), isNull);
    });

    test('the future stays pending until complete is called', () async {
      final future = RxResult.wait<int>('res_c');
      var completed = false;
      future.then((_) => completed = true);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(completed, isFalse);

      RxResult.complete('res_c', 1);
      await future.timeout(timeout);
      expect(completed, isTrue);
    });

    test('completing an unknown pageId does not throw', () {
      expect(() => RxResult.complete('res_unknown', 1), returnsNormally);
    });

    test('completing twice keeps the first value and does not throw', () async {
      final future = RxResult.wait<String>('res_d');

      RxResult.complete('res_d', 'first');

      expect(() => RxResult.complete('res_d', 'second'), returnsNormally);
      expect(await future.timeout(timeout), 'first');
    });

    test('several pending results are independent', () async {
      final first = RxResult.wait<String>('res_e1');
      final second = RxResult.wait<String>('res_e2');

      RxResult.complete('res_e2', 'B');
      RxResult.complete('res_e1', 'A');

      expect(await first.timeout(timeout), 'A');
      expect(await second.timeout(timeout), 'B');
    });
  });
}
