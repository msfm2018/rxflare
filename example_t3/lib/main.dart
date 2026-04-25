import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

import 'home_page.dart';
import 'detail_page.dart';

import 'login_page.dart';
import 'tab_page.dart';

void main() {
  rxr.d({
    "/home": RxDef(
      path: "/home", // ⭐ 必须加
      builder: () => const HomePage(),
    ),

    "/detail": RxDef(path: "/detail", builder: () => const DetailPage()),

    "/tab": RxDef(path: "/tab", builder: () => const TabPage()),

    "/login": RxDef(
      path: "/login",
      builder: () => const LoginPage(),
      guard: () async {
        debugPrint("🔐 guard check");
        return true;
      },
    ),
  });

  // root stack
  rxr.memPages.value = [RxPage(name: "/home", pageId: "root")];

  // tab stack
  // rxr.initTab(0, [RxPage(name: "/tab", pageId: "tab_root")]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerDelegate: RxRouterDelegate(), routeInformationParser: RxRouteParser());
  }
}
