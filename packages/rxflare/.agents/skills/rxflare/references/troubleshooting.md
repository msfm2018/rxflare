# RxFlare troubleshooting guide

Use this as a diagnostic sequence, not as a list of guaranteed fixes. Confirm every proposed API against the checked-out source.

## 1. Import or symbol not found

1. Confirm the dependency exists in the app's `pubspec.yaml`.
2. Confirm the correct public entrypoint:
   - core: `package:rxflare_core/rxflare_core.dart`
   - router: `package:rxflare_router/rxflare_router.dart`
   - i18n: `package:rxflare_i18n/rxflare_i18n.dart`
   - umbrella: `package:rxflare/rxflare.dart`
3. Check that the symbol is re-exported by that entrypoint.
4. Run `flutter pub get` from the app/workspace package.
5. In a Melos workspace, inspect path dependencies and `melos.yaml` before running workspace scripts.

Do not solve an import error by importing a private `lib/src/...` file in application code.

## 2. Rx widget does not rebuild

Check:

- Is the reactive value read inside the `Rx`/`RxBuilder` builder, rather than before it?
- Is the mutation made through `.value` or the reactive collection's supported mutation API?
- Is a raw List/Map/Set reference being mutated directly?
- Is the code using `untracked` around a read that should be tracked?
- Is the relevant dependency field/index actually read inside that builder?
- Has the state already been disposed?

For `RxList`, `list[index]` is field/index tracked; `list.value` is a whole-state read. For `RxMap`, `map[key]` tracks the key. `RxSet.contains/length` track the set state.

## 3. Effect or watch timing surprises

`effect` executes immediately and coalesces dependency-triggered reruns through a microtask. In tests, await a microtask boundary before asserting a rerun. `watch` evaluates its source immediately and calls its callback immediately by default; `immediate: false` suppresses only the first callback.

Always call the returned stop function when the owner is finished. If an effect callback throws, the current implementation keeps its previous dependency set; inspect `effect-watch.md` before changing exception handling.

## 4. `RxLocale.current` throws

Call `RxLocale.init()` before accessing `RxLocale.current`, `RxLocale.locale`, or translation helpers. The getter intentionally throws a `StateError` before initialization.

If translations are missing, check the normalized locale key, country-specific key, language-only fallback, English fallback, then the original key. For JSON bundles, verify the asset path is declared in `pubspec.yaml` and the filename corresponds to the locale key.

Remember that RxLocale does not automatically provide Material/Cupertino localization delegates.

## 5. Route does not open

Check:

- Was the route registered with `RxRouter.register()` or through `RxWidgetsApp`?
- Does `RxRoute.builder` use a zero-argument callback?
- Does the incoming URI have the same number of path segments as the route pattern?
- Are dynamic segments written as `:id` and accessed using `rxr.param('id')`?
- Is a guard returning `false`?
- Is the URL being passed as a valid URI string?

Unknown routes return no match; `to()` returns `null` without pushing a page.

## 6. Browser URL and route stack disagree

Inspect the two state machines separately:

1. What URL is in `RouteInformationProvider.value`?
2. What URL did the delegate report?
3. What is `RxRouterDelegate.currentConfiguration`?
4. What pages are in the configured stack?
5. Did Flutter call `setNewRoutePath` for the provider change?
6. Did the delegate recognize the target as the previous stack page and call `back()`, or call `to()`?

When using `FakeBrowserProvider`, verify its `history` and `historyIndex` before debugging delegate code. See the diagnostic order in `routing.md`.

## 7. Material localization or Material widget errors

`rxflare_core` and `rxflare_router` are intentionally design-system agnostic. `RxWidgetsApp` wraps `WidgetsApp.router`; it does not automatically install Material localization delegates. If using Material widgets, supply a Material app/localization setup appropriate to the Flutter SDK and ensure the widget tree has the required localization and theme ancestors.

Do not add Material imports to the core/router packages just to fix an application-level ancestor issue.

## 8. Resource leaks or stale callbacks

- Stop `effect`/`watch` subscriptions.
- Invoke listener cancellation callbacks returned by `listen`/`bind`.
- Dispose `RxComputed` and `RxFuture` instances you own.
- Cancel event subscriptions by token or remove their listener.
- Dispose `RxRouterDelegate` when manually owning it.
- Use `RxAutoDispose` for resources owned by a `State`.
- Avoid registering one global DI key from multiple simultaneously mounted `RxProvider`s.

After fixing a lifecycle bug, add a regression test that mounts, updates, disposes, and verifies no further callback or notification occurs.
