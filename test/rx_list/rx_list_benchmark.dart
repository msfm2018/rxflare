import 'dart:math';

void benchmarkListUpdate(int size) {
  final list = List<int>.generate(size, (i) => i);

  final stopwatch = Stopwatch()..start();

  const iterations = 1000;

  for (var i = 0; i < iterations; i++) {
    final index = Random(i).nextInt(size);

    final oldValue = list[index];
    final newValue = oldValue + 1;

    if (oldValue == newValue) continue;

    final newList = List<int>.of(list);
    newList[index] = newValue;
  }

  stopwatch.stop();

  // ignore: avoid_print
  print(
    'List Size: $size | '
    'Iterations: $iterations | '
    'Total: ${stopwatch.elapsedMicroseconds} μs | '
    'Average: ${stopwatch.elapsedMicroseconds / iterations} μs',
  );
}

void main() {
  for (final size in [100, 1000, 10000, 100000]) {
    benchmarkListUpdate(size);
  }
}
