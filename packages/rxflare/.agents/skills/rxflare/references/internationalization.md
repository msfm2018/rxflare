# RxLocale internationalization

Source of truth:
- `rxflare_i18n/lib/src/rx_locale.dart`
- `rxflare_i18n/lib/rxflare_i18n.dart`
- `rxflare_i18n/test/rx_locale_test.dart`

## Import

```dart
import 'package:rxflare_i18n/rxflare_i18n.dart';
// Or: import 'package:rxflare/rxflare.dart';
```

## Initialize

Call `RxLocale.init` before reading `RxLocale.locale`, `RxLocale.current`, or using a translation extension:

```dart
import 'package:flutter/widgets.dart';
import 'package:rxflare_i18n/rxflare_i18n.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  RxLocale.init(
    supported: const [
      Locale('en'),
      Locale('zh', 'CN'),
      Locale('zh', 'TW'),
      Locale('ja'),
    ],
    initialLocale: const Locale('zh', 'CN'),
    followSystem: false,
    translations: {
      'en': {
        'app.title': 'Hello',
        'greeting': 'Hello {name}',
      },
      'zh_cn': {
        'app.title': '你好',
        'greeting': '你好，{name}',
      },
    },
  );

  runApp(const MyApp());
}
```

Important behavior:

- `followSystem` defaults to `true`.
- `supported` replaces the supported locale list when it is non-empty.
- `initialLocale` is resolved against supported locales. Exact language+country match is preferred, then language-only match, then the first supported locale.
- When `followSystem` is true, the current system locale is synchronized after initialization and on platform locale changes.
- `setLocale()` switches to manual mode. `followSystem()` returns to system-following mode.
- `RxLocale.init()` is guarded after the first initialization. Later calls do not replace supported locales or the current locale; they only merge translations when `translations != null` and `mergeTranslations == true`.
- Call `RxLocale.dispose()` when a test or lifecycle explicitly owns the global locale state and needs to reset it.

## Translation lookup

```dart
final title = 'app.title'.tr;
final greeting = 'greeting'.trParams({'name': 'Ada'});
```

Equivalent static calls:

```dart
RxLocale.tr('app.title');
RxLocale.tr('greeting', params: {'name': 'Ada'});
```

Lookup fallback order for ordinary translations:

1. language + country key, normalized to lowercase with `_`;
2. language-only key;
3. English (`en`);
4. the key itself.

Parameter placeholders use `{parameterName}`. Missing parameters remain unchanged in the returned text.

Because `RxLocale.locale` reads the reactive `current` state, translations used inside an `Rx`/`RxBuilder` build are reevaluated when the locale changes.

## Plural templates

The current implementation supports a small custom template syntax, not a complete ICU MessageFormat implementation:

```dart
final itemText = 'items'.trPlural(3);
```

Example translation entry:

```dart
'items': '{count,plural,=0{No items}=1{One item}other{{count} items}}',
```

Supported branch labels in the parser include exact numeric branches such as `=0`, and the labels `zero`, `one`, and `other`. Although the parser recognizes `two`, `few`, and `many` labels, this snapshot only selects the explicit `zero`, `one`, and exact-number branches plus `other`. Do not promise complete locale-specific plural rules.

If no plural template exists, `trPlural` falls back to the ordinary translation and injects `{count}`. A `params['count']` value overrides the rendered count placeholder.

## Load JSON assets

`loadJsonBundle` derives the locale key from the asset file basename (without extension), normalizes hyphens/underscores and case, and accepts string values from a JSON object.

Example files:

`assets/i18n/en.json`

```json
{
  "app.title": "Hello",
  "greeting": "Hello {name}"
}
```

`assets/i18n/zh_CN.json`

```json
{
  "app.title": "你好",
  "greeting": "你好，{name}"
}
```

Declare assets in the app's `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/i18n/
```

Load before the first frame:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  RxLocale.init(
    supported: const [Locale('en'), Locale('zh', 'CN')],
    followSystem: true,
  );

  await RxLocale.loadJsonBundles([
    'assets/i18n/en.json',
    'assets/i18n/zh_CN.json',
  ]);

  runApp(const MyApp());
}
```

`loadJsonBundle` catches load/parse errors and writes a debug message; callers do not receive the exception. `merge` defaults to `true`; use `false` to replace that locale's normal and plural maps.

## Persist manual language selection

RxLocale does not choose a storage package. Use the `onSaveLocale` callback to connect application-owned persistence:

```dart
RxLocale.onSaveLocale = (locale) {
  final storedValue = RxLocale.localeToString(locale);
  // Save storedValue with the app's own preferences/database layer.
};
```

Restore a stored locale by parsing it with `localeFromString` and passing the result as `initialLocale` during the first `init` call. The callback type is `void Function(Locale)`; do not assume RxLocale awaits asynchronous persistence work.

Helpers:

```dart
final serialized = RxLocale.localeToString(const Locale('zh', 'CN')); // zh_CN
final locale = RxLocale.localeFromString('zh-CN');
```

## Flutter app localization integration

`RxLocale` supplies translation lookup and a reactive locale state. It does **not** export Flutter's Material/Cupertino localization delegates or automatically configure `MaterialApp`/`WidgetsApp` delegates. The app must still configure the appropriate `localizationsDelegates`, `supportedLocales`, and locale behavior for framework widgets that need them.

`RxWidgetsApp` accepts `locale`, `localizationsDelegates`, `supportedLocales`, and locale resolution callbacks and forwards them to `WidgetsApp.router`. It does not automatically bind its `locale` property to `RxLocale.current`.

## Tests in this archive

`rx_locale_test.dart` covers locale matching/fallback, parameter substitution, plural branches, locale-key normalization, manual locale changes, translation merging, JSON bundle loading, serialization helpers, and system-locale behavior. Check the exact test before assuming a boundary case is covered.
