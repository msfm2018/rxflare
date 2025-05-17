import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'home.dart';
import 'services/api_service.dart';
import 'services/shared_preferences.dart';

class EnterpriseLoginPage extends StatefulWidget {
  const EnterpriseLoginPage({super.key});

  @override
  State<EnterpriseLoginPage> createState() => _EnterpriseLoginPageState();
}

class _EnterpriseLoginPageState extends State<EnterpriseLoginPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  Future<void> _login() async {
    final username = _userController.text.trim();
    final password = _passController.text.trim();

    final result = await ApiService.login(username, password);
    if (result != null && result['token'] != null) {
      // 登录成功后缓存 Token
      await AuthService.saveToken(result['token']);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home()));
      // 登录
    }
    if (username == 'admin' && password == 'admin') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home()));
    } else {
      Fluttertoast.showToast(msg: "账号或密码错误", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景图片
          SizedBox.expand(child: Image.network('https://images.pexels.com/photos/9499417/pexels-photo-9499417.jpeg?auto=compress&cs=tinysrgb&w=600&lazy=load', fit: BoxFit.cover)),
          // 半透明遮罩
          Container(color: Colors.black.withAlpha(80)),
          // 登录框
          Center(
            child: Container(
              width: 420,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(200),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 8))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(backgroundColor: Colors.blueAccent, radius: 40, child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.white)),
                  const SizedBox(height: 20),
                  const Text("企业后台登录", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _userController,
                    decoration: InputDecoration(hintText: '用户名', prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: InputDecoration(hintText: '密码', prefixIcon: const Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [Checkbox(value: true, onChanged: (_) {}), const Text("记住密码"), const Spacer(), TextButton(onPressed: () {}, child: const Text("忘记密码?"))]),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text("登录", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(onPressed: () {}, child: const Text("没有账号？立即注册")),
                  TextButton(onPressed: () {}, child: const Text("账号密码：admin，admin")),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
