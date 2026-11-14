import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare/rxflare.dart';

void main() {
  group('batch', () {
    test('coalesces multiple writes into one notification', () {
      final a = 0.obs;
      final b = 0.obs;
      var notifyCount = 0;

      a.addListener((_) => notifyCount++);
      b.addListener((_) => notifyCount++);

      batch(() {
        a.value = 1;
        b.value = 2;
        a.value = 3;
      });

      expect(a.value, 3);
      expect(b.value, 2);
      // Each state is flushed once at the end of the batch.
      expect(notifyCount, 2);
    });

    test('nested batches flush only at outermost end', () {
      final x = 0.obs;
      var count = 0;
      x.addListener((_) => count++);

      batch(() {
        x.value = 1;
        batch(() {
          x.value = 2;
        });
        x.value = 3;
      });

      expect(x.value, 3);
      expect(count, 1);
    });

    test('writes outside batch still notify immediately', () {
      final x = 0.obs;
      var count = 0;
      x.addListener((_) => count++);

      x.value = 1;
      expect(count, 1);
      x.value = 2;
      expect(count, 2);
    });
  });

  group('untracked', () {
    test('does not register dependencies while reading', () {
      final a = 1.obs;
      final b = 2.obs;

      final c = computed(() {
        final av = a.value;
        final bv = untracked(() => b.value);
        return av + bv;
      });

      expect(c.value, 3);

      var recomputes = 0;
      c.addListener((_) => recomputes++);

      // Changing b should NOT recompute c (read was untracked).
      b.value = 10;
      expect(recomputes, 0);
      expect(c.value, 3); // stale until a changes, by design of untracked

      // Changing a should recompute and pick up the latest b.
      a.value = 5;
      expect(recomputes, 1);
      expect(c.value, 15);
    });
  });
}
