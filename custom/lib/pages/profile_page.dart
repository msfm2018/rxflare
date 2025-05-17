import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  final TextEditingController _passwordController = TextEditingController();

  void _logout(BuildContext context) async {
    await AuthService.logout();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
  }

  void _changePassword() {
    // TODO: 调用实际接口
    print("修改密码为：${_passwordController.text}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("个人中心")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text("当前账号：user123"),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: "新密码"), obscureText: true),
            SizedBox(height: 10),
            ElevatedButton(onPressed: _changePassword, child: Text("修改密码")),
            ElevatedButton(onPressed: () => _logout(context), child: Text("退出登录")),
          ],
        ),
      ),
    );
  }
}
