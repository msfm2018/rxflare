import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart' as getx;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:signals/signals_flutter.dart';
import 'package:mobx/mobx.dart' as mobx;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:rxflare/rxflare.dart' as rxflare;

const int iterations = 20000;
const int warmup = 2000;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BenchApp());
}

class BenchApp extends StatelessWidget {
  const BenchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BenchPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BenchPage extends StatefulWidget {
  const BenchPage({super.key});

  @override
  State<BenchPage> createState() => _BenchPageState();
}

class _BenchPageState extends State<BenchPage> {
  final logs = <String>[];
  bool running = false;

  void log(String msg) {
    setState(() => logs.add(msg));
    // ignore: avoid_print
    print(msg);
  }

  Future<void> runAll() async {
    if (running) return;
    setState(() {
      running = true;
      logs.clear();
    });

    log('=== UI Rebuild Benchmark (batched, no per-frame wait) ===');
    log('Iterations: $iterations\n');

    for (final widgetCount in [1, 10]) {
      log('---------- Widgets listening: $widgetCount ----------');
      await benchValueNotifier(widgetCount);
      await benchGetX(widgetCount);
      await benchRiverpod(widgetCount);
      await benchChangeNotifier(widgetCount);
      await benchCubit(widgetCount);
      await benchSignals(widgetCount);
      await benchMobX(widgetCount);
      await benchRxFlare(widgetCount);
      log('');
    }

    log('=== Done ===');
    setState(() => running = false);
  }

  /// 只在需要刷帧时调用，不再每次更新都等
  Future<void> waitFrames([int count = 3]) async {
    for (var i = 0; i < count; i++) {
      final completer = Completer<void>();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!completer.isCompleted) completer.complete();
      });
      SchedulerBinding.instance.scheduleFrame();
      await completer.future;
    }
  }

  void printResult(String name, Stopwatch sw) {
    final totalUs = sw.elapsedMicroseconds;
    final avgUs = totalUs / iterations;
    log('${name.padRight(26)} | ${totalUs.toString().padLeft(10)} us | ${avgUs.toStringAsFixed(3).padLeft(9)} us/update');
  }

  // ==================== ValueNotifier ====================
  Future<void> benchValueNotifier(int widgetCount) async {
    final counter = ValueNotifier<int>(0);
    final key = GlobalKey();

    await _mount(
      key: key,
      child: Column(
        children: List.generate(
          widgetCount,
          (i) => ValueListenableBuilder<int>(
            valueListenable: counter,
            builder: (_, v, __) => Text('$v', key: ValueKey('vn_$i')),
          ),
        ),
      ),
    );

    for (var i = 0; i < warmup; i++) counter.value = i;
    await waitFrames(2);

    final sw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      counter.value = i;
    }
    await waitFrames(3); // 最后刷干净
    sw.stop();

    printResult('ValueNotifier', sw);
    counter.dispose();
    await _unmount(key);
  }

  // ==================== GetX ====================
  Future<void> benchGetX(int widgetCount) async {
    final counter = getx.RxInt(0);
    final key = GlobalKey();

    await _mount(
      key: key,
      child: Column(
        children: List.generate(
          widgetCount,
          (i) => getx.Obx(() => Text('${counter.value}', key: ValueKey('getx_$i'))),
        ),
      ),
    );

    for (var i = 0; i < warmup; i++) counter.value = i;
    await waitFrames(2);

    final sw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      counter.value = i;
    }
    await waitFrames(3);
    sw.stop();

    printResult('GetX (Obx)', sw);
    await _unmount(key);
  }

  // ==================== Riverpod ====================
  Future<void> benchRiverpod(int widgetCount) async {
    final container = ProviderContainer();
    final provider = NotifierProvider<CounterNotifier, int>(CounterNotifier.new);
    final key = GlobalKey();

    await _mount(
      key: key,
      child: UncontrolledProviderScope(
        container: container,
        child: Column(
          children: List.generate(
            widgetCount,
            (i) => Consumer(
              builder: (_, ref, __) {
                final v = ref.watch(provider);
                return Text('$v', key: ValueKey('rp_$i'));
              },
            ),
          ),
        ),
      ),
    );

    for (var i = 0; i < warmup; i++) {
      container.read(provider.notifier).set(i);
    }
    await waitFrames(2);

    final sw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      container.read(provider.notifier).set(i);
    }
    await waitFrames(3);
    sw.stop();

    printResult('Riverpod', sw);
    container.dispose();
    await _unmount(key);
  }

  // ==================== ChangeNotifier ====================
  Future<void> benchChangeNotifier(int widgetCount) async {
    final counter = SimpleCounter();
    final key = GlobalKey();

    await _mount(
      key: key,
      child: AnimatedBuilder(
        animation: counter,
        builder: (_, __) {
          return Column(
            children: List.generate(
              widgetCount,
              (i) => Text('${counter.value}', key: ValueKey('cn_$i')),
            ),
          );
        },
      ),
    );

    for (var i = 0; i < warmup; i++) counter.value = i;
    await waitFrames(2);

    final sw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      counter.value = i;
    }
    await waitFrames(3);
    sw.stop();

    printResult('ChangeNotifier', sw);
    counter.dispose();
    await _unmount(key);
  }

  // ==================== Bloc Cubit ====================
  Future<void> benchCubit(int widgetCount) async {
    final cubit = CounterCubit();
    final key = GlobalKey();

    await _mount(
      key: key,
      child: BlocProvider.value(
        value: cubit,
        child: Column(
          children: List.generate(
            widgetCount,
            (i) => BlocBuilder<CounterCubit, int>(
              builder: (_, v) => Text('$v', key: ValueKey('bloc_$i')),
            ),
          ),
        ),
      ),
    );

    for (var i = 0; i < warmup; i++) cubit.set(i);
    await waitFrames(2);

    final sw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      cubit.set(i);
    }
    await waitFrames(3);
    sw.stop();

    printResult('Bloc Cubit', sw);
    await cubit.close();
    await _unmount(key);
  }

  // ==================== Signals ====================
  Future<void> benchSignals(int widgetCount) async {
    final counter = signal(0);
    final key = GlobalKey();

    await _mount(
      key: key,
      child: Column(
        children: List.generate(
          widgetCount,
          (i) => Watch((context) => Text('${counter.value}', key: ValueKey('sig_$i'))),
        ),
      ),
    );

    for (var i = 0; i < warmup; i++) counter.value = i;
    await waitFrames(2);

    final sw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      counter.value = i;
    }
    await waitFrames(3);
    sw.stop();

    printResult('Signals (Watch)', sw);
    await _unmount(key);
  }

  // ==================== MobX ====================
  Future<void> benchMobX(int widgetCount) async {
    final counter = mobx.Observable<int>(0);
    final key = GlobalKey();

    await _mount(
      key: key,
      child: Column(
        children: List.generate(
          widgetCount,
          (i) => Observer(
            builder: (_) => Text('${counter.value}', key: ValueKey('mobx_$i')),
          ),
        ),
      ),
    );

    for (var i = 0; i < warmup; i++) {
      mobx.runInAction(() => counter.value = i);
    }
    await waitFrames(2);

    final sw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      mobx.runInAction(() => counter.value = i);
    }
    await waitFrames(3);
    sw.stop();

    printResult('MobX (Observer)', sw);
    await _unmount(key);
  }

  // ==================== RxFlare ====================
  Future<void> benchRxFlare(int widgetCount) async {
    final counter = rxflare.RxState<int>(0);
    final key = GlobalKey();

    await _mount(
      key: key,
      child: Column(
        children: List.generate(
          widgetCount,
          (i) => rxflare.Rx(
            () => Text('${counter.value}', key: ValueKey('rx_$i')),
          ),
        ),
      ),
    );

    for (var i = 0; i < warmup; i++) counter.value = i;
    await waitFrames(2);

    final sw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      counter.value = i;
    }
    await waitFrames(3);
    sw.stop();

    printResult('RxFlare (Rx)', sw);
    counter.dispose();
    await _unmount(key);
  }

  // ---------- 挂载 / 卸载 ----------
  final _overlayKey = GlobalKey<OverlayState>();
  final _entries = <GlobalKey, OverlayEntry>{};

  Future<void> _mount({required GlobalKey key, required Widget child}) async {
    final overlay = _overlayKey.currentState;
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (_) => Material(
        child: Center(child: KeyedSubtree(key: key, child: child)),
      ),
    );
    overlay.insert(entry);
    _entries[key] = entry;
    await waitFrames(2);
  }

  Future<void> _unmount(GlobalKey key) async {
    final entry = _entries.remove(key);
    entry?.remove();
    await waitFrames(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UI Rebuild Bench')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: running ? null : runAll,
              child: Text(running ? 'Running...' : 'Start Benchmark'),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Overlay(key: _overlayKey),
                ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: logs.length,
                  itemBuilder: (_, i) => Text(
                    logs[i],
                    style: const TextStyle(fontFamily: 'Consolas', fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int v) => state = v;
}

class SimpleCounter extends ChangeNotifier {
  int _value = 0;
  int get value => _value;
  set value(int v) {
    _value = v;
    notifyListeners();
  }
}

class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void set(int v) => emit(v);
}