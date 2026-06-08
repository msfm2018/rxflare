/// RxFlare Routing Module
///
/// A lightweight Navigator 2.0 based routing solution with the following features:
///
/// - Path parameters (`/detail/:id`)
/// - Query parameters (`?type=hot`)
/// - Object passing between pages
/// - Page result returning (`await to()` + `back(result: ...)`)
/// - Route guards
/// - Multi-tab nested routing support
///
/// ### Recommended Usage:
///
/// ```dart
/// RxMaterialApp(
///   routes: AppRoutes.routes,
///   initialRoute: "/",
/// )
/// ```

export 'rx_router_core.dart'; // Core router logic (RxRouter, rxr, etc.)
export 'rx_route_args.dart'; // Arguments and parameter management
export 'rx_stack.dart'; // Internal dependency stack (used by routing)
export 'rx_material_app.dart';    // Convenient MaterialApp.router wrapper