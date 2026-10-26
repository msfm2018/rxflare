import 'package:flutter/widgets.dart';

import 'rx_router.dart';

/// A style-agnostic wrapper around [WidgetsApp.router] for the RxFlare routing system.
///
/// Does NOT introduce Material or Cupertino design.
/// You can wrap it with your own design system (Material, Cupertino, custom, etc.).
class RxWidgetsApp extends StatelessWidget {
  /// The route map to register with [RxRouter].
  final Map<String, RxRoute> routes;

  /// The initial route. Defaults to `"/"`.
  final String initialRoute;

  // ── WidgetsApp.router parameters ──
  final RouteInformationProvider? routeInformationProvider;
  final BackButtonDispatcher? backButtonDispatcher;
  final TransitionBuilder? builder;
  final String? title;
  final GenerateAppTitle? onGenerateTitle;
  final Color? color;
  final Locale? locale;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final LocaleListResolutionCallback? localeListResolutionCallback;
  final LocaleResolutionCallback? localeResolutionCallback;
  final Iterable<Locale>? supportedLocales;
  final bool showPerformanceOverlay;
  final bool showSemanticsDebugger;
  final bool debugShowCheckedModeBanner;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;
  final String? restorationScopeId;
  final bool useInheritedMediaQuery;

  const RxWidgetsApp({
    super.key,
    required this.routes,
    this.initialRoute = "/",
    this.routeInformationProvider,
    this.backButtonDispatcher,
    this.builder,
    this.title,
    this.onGenerateTitle,
    this.color,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales,
    this.showPerformanceOverlay = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = false,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.useInheritedMediaQuery = false,
  });

  @override
  Widget build(BuildContext context) {
    // Auto setup RxFlare router
    rxr.register(routes);
    rxr.initialRoute = initialRoute;
    rxr.ensureInitialized();

    return WidgetsApp.router(
      color: color ?? const Color(0xFF000000),
      routeInformationProvider: routeInformationProvider,
      routeInformationParser: RxRouteParser(),
      routerDelegate: RxRouterDelegate(),
      backButtonDispatcher: backButtonDispatcher,
      builder: builder,
      title: title,
      onGenerateTitle: onGenerateTitle,
      locale: locale,
      localizationsDelegates: localizationsDelegates,
      localeListResolutionCallback: localeListResolutionCallback,
      localeResolutionCallback: localeResolutionCallback,
      supportedLocales: supportedLocales ?? const <Locale>[Locale('en', 'US')],
      showPerformanceOverlay: showPerformanceOverlay,
      showSemanticsDebugger: showSemanticsDebugger,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      shortcuts: shortcuts,
      actions: actions,
      restorationScopeId: restorationScopeId,
    );
  }
}
