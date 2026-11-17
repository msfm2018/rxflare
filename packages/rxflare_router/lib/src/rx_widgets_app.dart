import 'package:flutter/widgets.dart';

import 'rx_route_args.dart';
import 'rx_router_core.dart';

/// A style-agnostic wrapper around [WidgetsApp.router] for the RxFlare routing system.
///
/// Does NOT introduce Material or Cupertino design.
/// You can wrap it with your own design system (Material, Cupertino, custom, etc.).
class RxWidgetsApp extends StatefulWidget {
  /// The route map to register with [RxRouter].
  ///
  /// Routes are registered once when this widget is initialized.
  final Map<String, RxRoute> routes;

  /// The initial route. Defaults to "/".
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
  State<RxWidgetsApp> createState() => _RxWidgetsAppState();
}

class _RxWidgetsAppState extends State<RxWidgetsApp> {
  late final RxRouterDelegate _routerDelegate;

  @override
  void initState() {
    super.initState();

    final router = RxRouter.I;

    // Register routes only once during widget initialization.
    router.register(widget.routes);

    // Set the initial route before creating the delegate.
    router.initialRoute = widget.initialRoute;

    // The delegate initializes the router if necessary.
    _routerDelegate = RxRouterDelegate();
  }

  @override
  void dispose() {
    // Release RxState listeners owned by this delegate.
    _routerDelegate.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WidgetsApp.router(
      color: widget.color ?? const Color(0xFF000000),
      routeInformationProvider: widget.routeInformationProvider,
      routeInformationParser: RxRouteParser(),
      routerDelegate: _routerDelegate,
      backButtonDispatcher: widget.backButtonDispatcher,
      builder: widget.builder,
      title: widget.title,
      onGenerateTitle: widget.onGenerateTitle,
      locale: widget.locale,
      localizationsDelegates: widget.localizationsDelegates,
      localeListResolutionCallback: widget.localeListResolutionCallback,
      localeResolutionCallback: widget.localeResolutionCallback,
      supportedLocales:
          widget.supportedLocales ?? const <Locale>[Locale('en', 'US')],
      showPerformanceOverlay: widget.showPerformanceOverlay,
      showSemanticsDebugger: widget.showSemanticsDebugger,
      debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
      shortcuts: widget.shortcuts,
      actions: widget.actions,
      restorationScopeId: widget.restorationScopeId,
    );
  }
}
