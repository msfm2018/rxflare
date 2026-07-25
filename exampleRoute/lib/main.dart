import 'dart:async';

import 'package:flutter/material.dart';
import 'package:layerx/layerx.dart';
import 'package:rxflare/rxflare.dart';
import 'app_routes.dart';

Future<void> main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RxBuilder(
      builder: (context) => RxMaterialApp(
        title: 'demo',

        routes: AppRoutes.routes,
        // you can safely omit initialRoute — it will automatically use "/".
        initialRoute: "/home",
        //use LayerX dialog
        builder: LayerX.init(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: MediaQuery.of(context).textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.6)),
              child: child!,
            );
          },
        ),
      ),
    );
  }
}
