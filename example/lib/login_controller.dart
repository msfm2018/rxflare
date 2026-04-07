import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

import 'login_auth.dart';

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
    final auth = RxObjMgr.find<AuthService>();
    isLoading.value = true;
    try {
      await auth.login(userCtrl.text, pwdCtrl.text);
    } catch (e) {
      isLoading.value = false;
      RxDebug.log("登录失败: $e");
    }
  }
}
