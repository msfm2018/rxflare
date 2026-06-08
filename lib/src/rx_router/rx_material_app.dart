import 'package:flutter/material.dart';
import 'rx_router.dart';

/// A convenient wrapper around [MaterialApp.router] for the RxFlare routing system.
///
/// This widget automatically:
/// - Registers the provided [routes]
/// - Sets [initialRoute] and calls [ensureInitialized]
/// - Provides `routerDelegate` and `routeInformationParser`
///
/// All other properties are forwarded to [MaterialApp.router].

class RxMaterialApp extends StatelessWidget {
  /// The route map to register with [RxRouter].
  final Map<String, RxRoute> routes;

  /// The initial route. Defaults to `"/"`.
  final String initialRoute;

  // ── MaterialApp.router parameters ──
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
  final RouteInformationProvider? routeInformationProvider;
  final BackButtonDispatcher? backButtonDispatcher;
  final TransitionBuilder? builder;
  final String? title;
  final GenerateAppTitle? onGenerateTitle;
  final NotificationListenerCallback<NavigationNotification>? onNavigationNotification;
  final Color? color;
  final ThemeData? theme;
  final ThemeData? darkTheme;
  final ThemeData? highContrastTheme;
  final ThemeData? highContrastDarkTheme;
  final ThemeMode? themeMode;

  final Duration themeAnimationDuration;
  final Curve? themeAnimationCurve;
  final Locale? locale;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final LocaleListResolutionCallback? localeListResolutionCallback;
  final LocaleResolutionCallback? localeResolutionCallback;
  final Iterable<Locale>? supportedLocales;
  final bool debugShowMaterialGrid;
  final bool showPerformanceOverlay;
  final bool checkerboardRasterCacheImages;
  final bool checkerboardOffscreenLayers;
  final bool showSemanticsDebugger;
  final bool debugShowCheckedModeBanner;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;
  final String? restorationScopeId;
  final ScrollBehavior? scrollBehavior;
  final bool useInheritedMediaQuery;
  final AnimationStyle? themeAnimationStyle;

  const RxMaterialApp({
    super.key,
    required this.routes,
    this.initialRoute = "/",
    this.scaffoldMessengerKey,
    this.routeInformationProvider,
    this.backButtonDispatcher,
    this.builder,
    this.title,
    this.onGenerateTitle,
    this.onNavigationNotification,
    this.color,
    this.theme,
    this.darkTheme,
    this.highContrastTheme,
    this.highContrastDarkTheme,
    this.themeMode,
    this.themeAnimationDuration = kThemeAnimationDuration,
    this.themeAnimationCurve,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales,
    this.debugShowMaterialGrid = false,
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = false,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.scrollBehavior,
    this.useInheritedMediaQuery = false,
    this.themeAnimationStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Auto setup RxFlare router
    rxr.register(routes);
    rxr.initialRoute = initialRoute;
    rxr.ensureInitialized();

    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      routeInformationProvider: routeInformationProvider,
      routeInformationParser: RxRouteParser(),
      routerDelegate: RxRouterDelegate(),
      backButtonDispatcher: backButtonDispatcher,
      builder: builder,
      title: title,
      onGenerateTitle: onGenerateTitle,
      onNavigationNotification: onNavigationNotification,
      color: color,
      theme: theme,
      darkTheme: darkTheme,
      highContrastTheme: highContrastTheme,
      highContrastDarkTheme: highContrastDarkTheme,
      themeMode: themeMode ?? ThemeMode.system,
      themeAnimationDuration: themeAnimationDuration,
      themeAnimationCurve: Curves.linear,
      locale: locale,
      localizationsDelegates: localizationsDelegates,
      localeListResolutionCallback: localeListResolutionCallback,
      localeResolutionCallback: localeResolutionCallback,
      supportedLocales: supportedLocales ?? const <Locale>[Locale('en', 'US')],
      debugShowMaterialGrid: debugShowMaterialGrid,
      showPerformanceOverlay: showPerformanceOverlay,
      checkerboardRasterCacheImages: checkerboardRasterCacheImages,
      checkerboardOffscreenLayers: checkerboardOffscreenLayers,
      showSemanticsDebugger: showSemanticsDebugger,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      shortcuts: shortcuts,
      actions: actions,
      restorationScopeId: restorationScopeId,
      scrollBehavior: scrollBehavior,
      // useInheritedMediaQuery: useInheritedMediaQuery,
      themeAnimationStyle: themeAnimationStyle,
    );
  }
}
