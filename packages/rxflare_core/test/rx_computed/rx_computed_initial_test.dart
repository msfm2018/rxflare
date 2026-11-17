import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_core/rxflare_core.dart';

void main() {
  group('RxComputed initial evaluation', () {
    test('computes once initially and tracks dependencies in that run', () {
      var computeCount = 0;
      final count = RxState<int>(10);

      final doubled = RxComputed<int>(() {
        computeCount++;
        return count.value * 2;
      });

      expect(computeCount, 1);
      expect(doubled.value, 20);

      count.value = 20;

      expect(computeCount, 2);
      expect(doubled.value, 40);

      doubled.dispose();
      count.dispose();
    });
  });
}
