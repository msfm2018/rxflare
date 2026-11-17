# Testing RxFlare applications and packages

The supplied monorepo uses Flutter's `flutter_test` package. Tests are organized by package under each package's `test/` directory.

## Test strategy

1. Test core state semantics without widgets where possible.
2. Use `testWidgets` for `Rx`, `RxBuilder`, router delegates, and page behavior.
3. Test lifecycle cleanup explicitly: dispose state, stop effects/watchers, cancel listeners, and dispose delegates/providers owned by the test.
4. For asynchronous behavior, wait for the documented scheduling boundary. Effects are microtask-scheduled; widget rebuilds need a tester pump. Do not use arbitrary delays when a microtask/pump boundary is sufficient.
5. Add a regression test that fails before the fix and passes after it.
6. Keep global singletons isolated. Reset `RxRouter.I` state and call `RxLocale.dispose()` between tests that mutate those singletons.

## Useful commands

Run from the relevant package directory:

```bash
flutter test
flutter analyze
```

Run one test file:

```bash
flutter test test/rx_router_web_test.dart
flutter test test/rx_locale_test.dart
```

Format changed files:

```bash
dart format lib test
```

For a Melos workspace, first inspect the workspace's `melos.yaml` and scripts. Do not assume a script name or package selector without checking the repository configuration.

## Core state tests

Useful existing test areas include:

- `rxflare_core/test/rx_batch/`
- `rxflare_core/test/rx_computed/`
- `rxflare_core/test/rx_effect/`
- `rxflare_core/test/rx_list/`
- `rxflare_core/test/rx_state/`
- `rxflare_core/test/rx_widget/`

When testing fine-grained rebuilds, count builder executions after the initial pump, mutate one field/index, pump once, and assert that only the widgets subscribed to that field/index rebuilt.

## Router tests

Useful existing tests include:

- `rx_router_navigation_test.dart`
- `rx_router_delegate_test.dart`
- `rx_router_delegate_widget_test.dart`
- `rx_router_set_new_route_path_test.dart`
- `rx_router_web_test.dart`
- `rx_router_tabs_test.dart`

For Web navigation, distinguish the fake browser's history state from the Rx route stack. Assert each layer separately: history entries/index, current URI, delegate behavior, route stack, and visible widget.

## Localization tests

`rxflare_i18n/test/rx_locale_test.dart` uses `TestWidgetsFlutterBinding.ensureInitialized()` and resets the global singleton with `RxLocale.dispose()` in setup/teardown. Follow that pattern when tests mutate locale state or load asset bundles.

## Avoid brittle tests

- Do not assert incidental internal listener counts unless that count is the behavior under test.
- Avoid depending on real wall-clock timing for microtask-driven effects.
- Do not use a fake `RouteInformationProvider` as proof that a real browser History API behaves identically; add browser integration coverage when real browser behavior is a release requirement.
- Do not assert performance based on a single debug-mode run. Use repeatable profile/release measurements and report device/runtime conditions.
