import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

import 'feature/features/home/controller/home_controller.dart';
import 'menu/screens/home_screen.dart';
import 'router_demo.dart';

class AppRoutes {
  static final routes = {
    "/": RxRoute(builder: () => MainTabWrapper()),
    "/RouterHomePage": RxRoute(builder: () => const RouterHomePage()),
    "/HomeScreen": RxRoute(builder: () => const HomeScreen()),
    "/admin": RxRoute(
      builder: () => const Scaffold(body: Center(child: Text("管理员专区"))),
      // 路由守卫：只有异步返回 true 才能进入
      guard: () async {
        debugPrint("守卫检查中...");
        // 模拟未登录，跳转登录并拦截
        final result = await rxr.to("/login");
        return result == "error";
      },
    ),
    "/login": RxRoute(builder: () => const LoginPage()),
    "/detail": RxRoute(builder: () => const DetailPage()),
    "/feature": RxRoute(builder: () => const FreatureHomePage()),
  };
}
