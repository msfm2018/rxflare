import 'package:rxflare/rxflare.dart';

import 'note_page.dart';

class AppRoutes {
  static final routes = {
    "/home": RxRoute(builder: () => const NotePage()),
  //   "/": RxRoute(builder: () => HomePage()), 
  //   "/intro": RxRoute(builder: () => const InfoPage()), // 注册介绍页
  // "/detail": RxRoute(builder: () => const DetailPage()), 
  // "/add": RxRoute(builder: () => const AddEditPage()), 
  // "/set": RxRoute(builder: () => const SettingsPage())
  };
}
