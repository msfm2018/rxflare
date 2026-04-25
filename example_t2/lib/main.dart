import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
import 'package:t/profile.dart';

import 'home_page.dart';
import 'tab_page.dart';
void main() {
  // 注册路由  rxr.d定义的地图      rxr.pages相当于行走的路径
  rxr.d({
    "/main": RxDef(path: "/main", builder: () => MainTabWrapper()), // 首页显示 Tab 外壳
    "/home": RxDef(path: "/home", builder: () => const HomePage()),
    "/profile": RxDef(path: "/profile", builder: () => const ProfilePage()),
    "/detail": RxDef(path: "/detail/:id", builder: () => const DetailPage()),
  });

  // 初始化根栈
  rxr.memPages.value = [
    RxPage(name: "/main", pageId: "app_root")
  ];

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: RxRouterDelegate(customStack: rxr.memPages),
      routeInformationParser: RxRouteParser(),

      
    );
  }
}
