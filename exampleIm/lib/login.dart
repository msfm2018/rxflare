import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
import 'loginController.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RxObjMgr.find<LoginController>();

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 280,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 30),
              TextField(
                controller: c.userCtrl,
                decoration: const InputDecoration(labelText: "账号"),
              ),
              TextField(
                controller: c.pwdCtrl,
                decoration: const InputDecoration(labelText: "密码"),
                obscureText: true,
              ),
              const SizedBox(height: 30),

              Rx(() => c.isLoading.value ? const CircularProgressIndicator() : _buildLoginButton(c)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(LoginController c) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
        onPressed: c.login,
        child: const Text("登 录"),
      ),
    );
  }
}
