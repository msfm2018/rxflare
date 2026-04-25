import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

import 'home_page.dart';
import 'profile.dart';

class MainTabWrapper extends StatefulWidget {
  @override
  State<MainTabWrapper> createState() => _MainTabWrapperState();
}

class _MainTabWrapperState extends State<MainTabWrapper> {
  @override
  void initState() {
    super.initState();
    // 初始化两个 Tab 的独立栈
    rxr.initTab(0, [RxPage(name: "/home", pageId: "tab0_root")]);
    rxr.initTab(1, [RxPage(name: "/profile", pageId: "tab1_root")]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: Router(
      //   // 关键点：传入当前 Tab 对应的 stack
      //   routerDelegate: RxRouterDelegate(
      //     customStack: rxr.tabPages[rxr.activeTabIndex],
      //   ),
      // ),
      body: IndexedStack(
        index: rxr.activeTabIndex,
        children: [
          Router(routerDelegate: RxRouterDelegate(customStack: rxr.tabPages[0])),
          Router(routerDelegate: RxRouterDelegate(customStack: rxr.tabPages[1])),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: rxr.activeTabIndex,
        onTap: (index) {
          setState(() {
            rxr.switchTab(index);
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "首页"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "我的"),
        ],
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body:Router(
  //       routerDelegate: RxRouterDelegate(),
  //       // 如果你的 Parser 也有逻辑，也可以加上，或者简单点：
  //       // routeInformationParser: RxRouteParser(),
  //     ),
  //     bottomNavigationBar: BottomNavigationBar(
  //       currentIndex: rxr.activeTabIndex,
  //       onTap: (index) {
  //         setState(() {
  //           rxr.switchTab(index);
  //         });
  //       },
  //       items: const [
  //         BottomNavigationBarItem(icon: Icon(Icons.home), label: "首页"),
  //         BottomNavigationBarItem(icon: Icon(Icons.person), label: "我的"),
  //       ],
  //     ),
  //   );
  // }
}
