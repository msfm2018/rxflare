import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart' as getx;
import 'package:riverpod/riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:signals/signals.dart';
import 'package:mobx/mobx.dart' as mobx;
import 'package:rxflare/rxflare.dart' as rxflare;

const int iterations = 1000000;
const int warmup = 100000;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('=== State Write Benchmark (with Listeners) ===');
  print('Iterations: $iterations\n');

  for (final listeners in [0, 1, 10]) {
    print('---------- Listeners: $listeners ----------');
    await benchValueNotifier(listeners);
    await benchGetX(listeners);
    await benchRiverpod(listeners);
    await benchChangeNotifier(listeners);
    await benchCubit(listeners);
    await benchSignals(listeners);
    await benchMobX(listeners);
    await benchRxFlare(listeners);
    print('');
  }

  print('=== Done ===');
}

void printResult(String name, Stopwatch sw) {
  final totalUs = sw.elapsedMicroseconds;
  final avgUs = totalUs / iterations;
  print('${name.padRight(26)} | ${totalUs.toString().padLeft(9)} us | ${avgUs.toStringAsFixed(4).padLeft(8)} us/write');
}

// ==================== ValueNotifier ====================
Future<void> benchValueNotifier(int listenerCount) async {
  final counter = ValueNotifier<int>(0);
  final disposers = <VoidCallback>[];

  for (var i = 0; i < listenerCount; i++) {
    void listener() {}
    counter.addListener(listener);
    disposers.add(() => counter.removeListener(listener));
  }

  for (var i = 0; i < warmup; i++) counter.value = i;

  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) counter.value = i;
  sw.stop();

  printResult('ValueNotifier', sw);
  for (final d in disposers) d();
  counter.dispose();
}

// ==================== GetX ====================
Future<void> benchGetX(int listenerCount) async {
  final counter = getx.RxInt(0);
  final workers = <getx.Worker>[];

  for (var i = 0; i < listenerCount; i++) {
    workers.add(getx.ever(counter, (_) {}));
  }

  for (var i = 0; i < warmup; i++) counter.value = i;

  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) counter.value = i;
  sw.stop();

  printResult('GetX (RxInt)', sw);
  for (final w in workers) w.dispose();
}

// ==================== Riverpod ====================
class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int v) => state = v;
}

final counterProvider = NotifierProvider<CounterNotifier, int>(CounterNotifier.new);

Future<void> benchRiverpod(int listenerCount) async {
  final container = ProviderContainer();
  final subscriptions = <ProviderSubscription<int>>[];

  for (var i = 0; i < listenerCount; i++) {
    subscriptions.add(container.listen(counterProvider, (_, __) {}));
  }

  for (var i = 0; i < warmup; i++) {
    container.read(counterProvider.notifier).set(i);
  }

  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    container.read(counterProvider.notifier).set(i);
  }
  sw.stop();

  printResult('Riverpod (Notifier)', sw);
  for (final s in subscriptions) s.close();
  container.dispose();
}

// ==================== ChangeNotifier ====================
class SimpleCounter extends ChangeNotifier {
  int _value = 0;
  int get value => _value;
  set value(int v) {
    _value = v;
    notifyListeners();
  }
}

Future<void> benchChangeNotifier(int listenerCount) async {
  final counter = SimpleCounter();
  final disposers = <VoidCallback>[];

  for (var i = 0; i < listenerCount; i++) {
    void listener() {}
    counter.addListener(listener);
    disposers.add(() => counter.removeListener(listener));
  }

  for (var i = 0; i < warmup; i++) counter.value = i;

  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) counter.value = i;
  sw.stop();

  printResult('ChangeNotifier', sw);
  for (final d in disposers) d();
  counter.dispose();
}

// ==================== Bloc Cubit ====================
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void set(int v) => emit(v);
}

Future<void> benchCubit(int listenerCount) async {
  final cubit = CounterCubit();
  final subscriptions = <StreamSubscription<int>>[];

  for (var i = 0; i < listenerCount; i++) {
    subscriptions.add(cubit.stream.listen((_) {}));
  }

  for (var i = 0; i < warmup; i++) cubit.set(i);

  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) cubit.set(i);
  sw.stop();

  printResult('Bloc Cubit', sw);
  for (final s in subscriptions) await s.cancel();
  await cubit.close();
}

// ==================== Signals ====================
Future<void> benchSignals(int listenerCount) async {
  final counter = signal(0);
  final cleanups = <EffectCleanup>[];

  for (var i = 0; i < listenerCount; i++) {
    cleanups.add(effect(() {
      counter.value; // track
    }));
  }

  for (var i = 0; i < warmup; i++) counter.value = i;

  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) counter.value = i;
  sw.stop();

  printResult('Signals', sw);
  for (final c in cleanups) c();
}

// ==================== MobX ====================
Future<void> benchMobX(int listenerCount) async {
  final counter = mobx.Observable<int>(0);
  final disposers = <mobx.ReactionDisposer>[];

  for (var i = 0; i < listenerCount; i++) {
    disposers.add(mobx.autorun((_) {
      counter.value; // track
    }));
  }

  for (var i = 0; i < warmup; i++) {
    mobx.runInAction(() => counter.value = i);
  }

  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    mobx.runInAction(() => counter.value = i);
  }
  sw.stop();

  printResult('MobX', sw);
  for (final d in disposers) d();
}

// ==================== RxFlare ====================
Future<void> benchRxFlare(int listenerCount) async {
  final counter = rxflare.RxState<int>(0);
  final disposers = <VoidCallback>[];

  for (var i = 0; i < listenerCount; i++) {
    final dispose = counter.listen((_) {});
    disposers.add(dispose);
  }

  for (var i = 0; i < warmup; i++) counter.value = i;

  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) counter.value = i;
  sw.stop();

  printResult('RxFlare (RxState)', sw);
  for (final d in disposers) d();
  counter.dispose();
}