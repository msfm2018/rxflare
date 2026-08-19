import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

import 'feature/features/home/controller/home_controller.dart';
import 'home_page.dart';
import 'menu/screens/home_screen.dart';
import 'note_page.dart';
import 'router_demo.dart';

class AppRoutes {
  static final routes = {
    "/": RxRoute(builder: () => const EnterprisePortalPage()),
    "/HomePage": RxRoute(builder: () => const HomePage()),
    "/home": RxRoute(builder: () => MainTabWrapper()),
    "/RouterHomePage": RxRoute(builder: () => const RouterHomePage()),
    "/HomeScreen": RxRoute(builder: () => const HomeScreen()),
    "/admin": RxRoute(
      builder: () => const Scaffold(body: Center(child: Text("管理员专区"))),
      guard: () async {
        debugPrint("守卫检查中...");
        final result = await rxr.to("/login");
        return result == "error";
      },
    ),
    "/login": RxRoute(builder: () => const LoginPage()),
    "/detail": RxRoute(builder: () => const DetailPage()),
    "/feature": RxRoute(builder: () => const FreatureHomePage()),
  };
}
