import 'package:flutter/material.dart';
import 'package:layerx/layerx.dart';
import 'package:rxflare/rxflare.dart';

import 'app_routes.dart';
import 'translations.dart';

// final isDarkMode = false.obs;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  RxLocale.init(
    translations: translations,
    // supported: RxLocale.supportedLocales,
  );
  // RxDebug.isEnabled = true;
  runApp(const RxFlareDemoApp());
}

class RxFlareDemoApp extends StatelessWidget {
  const RxFlareDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RxBuilder(
      builder: (context) => RxMaterialApp(
        title: 'demo',

        routes: AppRoutes.routes,
        // you can safely omit initialRoute — it will automatically use "/".
        // initialRoute: "/home",
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

  // @override
  // Widget build(BuildContext context) {
  //   return Rx(
  //     () => MaterialApp(
  //       title: 'app_title'.tr,
  //       theme: ThemeData.light(),
  //       darkTheme: ThemeData.dark(),
  //       themeMode: isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
  //       home: const HomePage(),
  //       debugShowCheckedModeBanner: false,
  //     ),
  //   );
  // }
}
