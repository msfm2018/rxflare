import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: const Center(
        child: Text("被 guard 控制的页面"),
      ),
    );
  }
}