import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

import 'entry.dart';

class AuthService {
  // final currentUser = RxValue<Map<String, dynamic>?>(null);
  final currentUser = RxValue<User?>(null);

  // ✅ 只要 currentUser 有值，就是登录状态
  late final isLogin = computed(() => currentUser.value != null);

  Future<void> login(String username, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // 模拟网络延迟
    if (username == "admin" && password == "123") {
      final user = User(
        id: "me",
        name: username, 
        avatar: "https://picsum.photos/200", // username.isNotEmpty ? username[0] : "我",
      );
      currentUser.value = user;
    } else {
      throw "账号或密码错误";
    }
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    currentUser.value = null; // ✅ 清空后，isLogin 自动变 false，main.dart 自动回跳
  }
}
