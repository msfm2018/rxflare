
import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

import 'loginAuth.dart';

class LoginController {
  final userCtrl = TextEditingController(text: "admin");
  final pwdCtrl = TextEditingController(text: "123");
  final isLoading = false.obs;

  // 被 RxParent 销毁时，这个方法会被执行
  void dispose() {
    userCtrl.dispose();
    pwdCtrl.dispose();
    RxDebug.log("🧹 LoginController: 文本控制器已释放");
  }

  void login() async {
    if (isLoading.value) return;
    final auth = RxGet.find<AuthService>();
    isLoading.value = true;
    try {
      await auth.login(userCtrl.text, pwdCtrl.text);
    } catch (e) {
      isLoading.value = false;
      print("登录失败: $e");
    }
  }
}