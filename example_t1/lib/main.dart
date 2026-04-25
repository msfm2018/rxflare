import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

import 'home_page.dart';

void main() {
  // 1. 注册所有路由
  rxr.d({
    "/": RxDef(path: "/", builder: () => HomePage()),
    "/detail": RxDef(path: "/detail/:id", builder: () => DetailPage()),
    "/login": RxDef(path: "/login", builder: () => LoginPage()),
    "/admin": RxDef(
      path: "/admin",
      builder: () => const Scaffold(body: Center(child: Text("管理员专区"))),
      // 路由守卫：只有异步返回 true 才能进入
      guard: () async {
        debugPrint("守卫检查中...");
        // 模拟未登录，跳转登录并拦截
        rxr.to("/login");
        return false;
      },
    ),
  });

  // 2. 初始化首页栈 (必须先放一个页面)
  rxr.memPages.value = [RxPage(name: "/", pageId: RxUtils.generateId())];

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RxRouter Demo',
      // 使用你定义的 Delegate 和 Parser
      routerDelegate: RxRouterDelegate(),
      routeInformationParser: RxRouteParser(),
    );
  }
}
