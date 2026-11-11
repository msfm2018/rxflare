import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_core/rxflare_core.dart';

void main() {
  group('effect', () {
    test('runs immediately and on dependency change', () async {
      final a = 0.obs;
      final seen = <int>[];
      final stop = effect(() {
        seen.add(a.value);
      });
      expect(seen, [0]);
      a.value = 1;
      await Future<void>.delayed(Duration.zero);
      expect(seen, [0, 1]);
      stop();
      a.value = 2;
      await Future<void>.delayed(Duration.zero);
      expect(seen, [0, 1]);
    });

    test('batch coalesces effect runs', () async {
      final a = 0.obs;
      final b = 0.obs;
      var runs = 0;
      effect(() {
        a.value;
        b.value;
        runs++;
      });
      expect(runs, 1);
      batch(() {
        a.value = 1;
        b.value = 2;
      });
      // effect re-runs are coalesced via scheduleMicrotask
      await Future<void>.delayed(Duration.zero);
      expect(runs, 2);
    });
  });

  group('watch', () {
    test('callback receives values', () async {
      final a = 1.obs;
      final values = <int>[];
      final stop = watch(() => a.value, values.add);
      expect(values, [1]);
      a.value = 5;
      await Future<void>.delayed(Duration.zero);
      expect(values, [1, 5]);
      stop();
    });
  });

  group('untracked in effect', () {
    test('untracked read does not subscribe', () async {
      final a = 1.obs;
      final b = 10.obs;
      var runs = 0;
      effect(() {
        a.value;
        untracked(() => b.value);
        runs++;
      });
      expect(runs, 1);
      b.value = 20;
      await Future<void>.delayed(Duration.zero);
      expect(runs, 1);
      a.value = 2;
      await Future<void>.delayed(Duration.zero);
      expect(runs, 2);
    });
  });
}
