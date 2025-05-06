import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
import 'widgets/testRxEvent.dart';
import 'widgets/testStateful.dart';
import 'widgets/testStateless.dart';

void main() {
  RxDebug.isEnabled = true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('事件通知示例')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: const [MyReactiveWidget(), SizedBox(height: 20), CounterScreen(), SizedBox(height: 20), SizedBox(height: 20), StringChangeListenerWidget()]),
        ),
      ),
    );
  }
}
