import 'package:material_ui/material_ui.dart';
import 'package:rxflare/rxflare.dart';

import 'app_routes.dart';
import 'translations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  RxLocale.init(translations: translations);
  runApp(const RxFlareDemoApp());
}

class RxFlareDemoApp extends StatelessWidget {
  const RxFlareDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: RxBuilder(
        builder: (context) => RxWidgetsApp(
          title: 'demo',
          routes: AppRoutes.routes,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,

          // supportedLocales: const [Locale('en', 'US'), Locale('zh', 'CN')],
        ),
      ),
    );
  }
}
