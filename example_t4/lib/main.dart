import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
import 'screens/home_screen.dart';

void main() {
  // RxFlare 初始化（可选开启调试）
  RxDebug.isEnabled = true;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '餐馆点菜',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
