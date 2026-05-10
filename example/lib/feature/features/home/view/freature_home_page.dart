// features/home/view/home_page.dart
import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
import '../controller/home_controller.dart';
import 'home_view.dart';

class FreatureHomePage extends StatelessWidget {
  const FreatureHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return RxParent<HomeController>(
      name: "homex",                    // 重要：多页面隔离
      dependency: HomeController(),
      child: const HomeView(),
    );
  }
}


