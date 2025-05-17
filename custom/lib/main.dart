import 'package:custom/login.dart';
import 'package:flutter/material.dart';

import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保绑定初始化（如果用到插件）

  bool loggedIn = await isLogin();
  if (loggedIn) {
    runApp(const MaterialApp(home: Home(), debugShowCheckedModeBanner: false));
  } else {
    runApp(const MaterialApp(home: EnterpriseLoginPage(), debugShowCheckedModeBanner: false));
  }
}

Future<bool> isLogin() async {
  // 模拟登录状态判断，或者调用本地存储等
  // bool res = await DataUtil.getIsLogin();

  bool res = false;
  return res;
}
