import 'package:flutter/material.dart';
import 'package:get/get.dart' as getx;
import 'package:riverpod/riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:signals/signals.dart';
import 'package:mobx/mobx.dart' as mobx;
import 'package:rxflare/rxflare.dart' as rxflare;

const int iterations = 1000000;
const int warmup = 200000;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('=== Flutter State Management Write Benchmark ===');
  print('Iterations: $iterations');
  print('Warmup: $warmup\n');

  await benchValueNotifier();
  await benchGetX();
  await benchRiverpod();
  await benchChangeNotifier();
  await benchCubit();
  await benchSignals();
  await benchMobX();
  await benchRxFlare();

  print('=== Done ===');
}

Future<void> benchValueNotifier() async {
  {
    final warm = ValueNotifier<int>(0);
    for (var i = 0; i < warmup; i++) warm.value = i;
    warm.dispose();
  }
  final counter = ValueNotifier<int>(0);
  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) counter.value = i;
  sw.stop();
  printResult('ValueNotifier', sw);
  counter.dispose();
}

Future<void> benchGetX() async {
  {
    final warm = getx.RxInt(0);
    for (var i = 0; i < warmup; i++) warm.value = i;
  }
  final counter = getx.RxInt(0);
  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) counter.value = i;
  sw.stop();
  printResult('GetX (RxInt)', sw);
}

class Counter extends Notifier<int> {
  @override
  int build() => 0;
  void set(int v) => state = v;
}

final counterProvider = NotifierProvider<Counter, int>(Counter.new);

Future<void> benchRiverpod() async {
  final container = ProviderContainer();
  {
    for (var i = 0; i < warmup; i++) {
      container.read(counterProvider.notifier).set(i);
    }
  }
  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    container.read(counterProvider.notifier).set(i);
  }
  sw.stop();
  printResult('Riverpod (Notifier)', sw);
  container.dispose();
}

class CounterNotifier extends ChangeNotifier {
  int _value = 0;
  int get value => _value;
  set value(int v) {
    _value = v;
    notifyListeners();
  }
}

Future<void> benchChangeNotifier() async {
  {
    final warm = CounterNotifier();
    for (var i = 0; i < warmup; i++) warm.value = i;
    warm.dispose();
  }
  final counter = CounterNotifier();
  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) counter.value = i;
  sw.stop();
  printResult('ChangeNotifier', sw);
  counter.dispose();
}

class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void set(int v) => emit(v);
}

Future<void> benchCubit() async {
  {
    final warm = CounterCubit();
    for (var i = 0; i < warmup; i++) warm.set(i);
    await warm.close();
  }
  final counter = CounterCubit();
  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) counter.set(i);
  sw.stop();
  printResult('Bloc Cubit', sw);
  await counter.close();
}

Future<void> benchSignals() async {
  {
    final warm = signal(0);
    for (var i = 0; i < warmup; i++) warm.value = i;
  }
  final counter = signal(0);
  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) counter.value = i;
  sw.stop();
  printResult('Signals', sw);
}

Future<void> benchMobX() async {
  {
    final warm = mobx.Observable<int>(0);
    for (var i = 0; i < warmup; i++) {
      mobx.runInAction(() => warm.value = i);
    }
  }
  final counter = mobx.Observable<int>(0);
  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    mobx.runInAction(() => counter.value = i);
  }
  sw.stop();
  printResult('MobX (Observable)', sw);
}

Future<void> benchRxFlare() async {
  {
    final warm = rxflare.RxState<int>(0);
    for (var i = 0; i < warmup; i++) warm.value = i;
    warm.dispose();
  }
  final counter = rxflare.RxState<int>(0);
  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) counter.value = i;
  sw.stop();
  printResult('RxFlare (RxState)', sw);
  counter.dispose();
}

void printResult(String name, Stopwatch sw) {
  final totalUs = sw.elapsedMicroseconds;
  final avgUs = totalUs / iterations;
  print('${name.padRight(28)} | Total: ${totalUs.toString().padLeft(10)} us | Avg: ${avgUs.toStringAsFixed(4).padLeft(8)} us / write');
}