import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxflare/src/core/rx_core.dart';

import '../core/rx_state.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await Hive.initFlutter();

//   final box = await Hive.openBox("settings");

//   final saved =
//       box.get("locale");

//   RxLocale.init(
//     translations: {

//       "en": {

//         "hello": "Hello",

//         "count":
//         "{count,plural,=0{No items}=1{One item}other{{count} items}}",

//       },

//       "zh": {

//         "hello": "你好",

//         "count":
//         "{count,plural,=0{没有}=1{一个}other{{count}个}}",

//       },

//     },

//     initialLocale:
//       saved != null
//       ? RxLocale.localeFromString(saved)
//       : null,

//     followSystem:
//       saved == null,

//   );

//   RxLocale.onSaveLocale =
//       (locale){

//     box.put(
//       "locale",
//       RxLocale.localeToString(locale),
//     );

//   };

//   runApp(
//     const MyApp()
//   );
// }

// class MyApp extends StatelessWidget {

//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context){

//     return MaterialApp(

//       home:
//       HomePage(),

//     );

//   }
// }
// class HomePage extends StatelessWidget {

//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context){

//     return Scaffold(

//       body:

//       Center(

//         child:

//         Column(

//           mainAxisAlignment:
//           MainAxisAlignment.center,

//           children:[

//             Text(
//               "hello".tr,
//             ),

//             Text(
//               "count"
//               .trPlural(5),
//             ),

//             ElevatedButton(

//               onPressed: (){

//                 RxLocale.setLocale(
//                   const Locale("zh"),
//                 );

//               },

//               child:
//               const Text(
//                 "中文",
//               ),

//             ),

//             ElevatedButton(

//               onPressed: (){

//                 RxLocale.followSystem();

//               },

//               child:
//               const Text(
//                 "跟随系统",
//               ),

//             ),

//           ],

//         ),

//       ),

//     );

//   }
// }

class _RxLocaleObserver extends WidgetsBindingObserver {
  @override
  void didChangeLocales(List<Locale>? locales) {
    if (RxLocale.isFollowingSystem) {
      RxLocale._syncWithSystem(
        WidgetsBinding.instance.platformDispatcher.locale,
      );
    }
  }
}

class RxLocale {
  static late final RxState<Locale> current;
  static final _observer = _RxLocaleObserver();
  static bool _followSystem = true;
  static bool get isFollowingSystem => _followSystem;
  static bool _initialized = false;

  /// 普通翻译文本
  static final Map<String, Map<String, String>> _translations = {};

  /// 复数模板 {langKey: {msgKey:pluralTemplate}}
  static final Map<String, Map<String, String>> _pluralTemplates = {};

  ///RxLocale.onSaveLocale = (locale) {
  /// box.put(
  ///  "locale",
  ///  RxLocale.localeToString(locale),
  /// );
  ///};

  static void Function(Locale locale)? onSaveLocale;

  /// 支持的语言列表（对外只读）
  static List<Locale> _supportedLocales = const [
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
    Locale('ja'),
    Locale('ko'),
    Locale('de'),
    Locale('fr'),
    Locale('es'),
    Locale('pt'),
    Locale('it'),
    Locale('ru'),
    Locale('ar'),
  ];

  static List<Locale> get supportedLocales => List.unmodifiable(_supportedLocales);

  /// RTL右到左语言判断
  static bool get isRTL {
    final lang = locale.languageCode;
    return const {'ar', 'fa', 'he', 'ur', 'ps'}.contains(lang);
  }

  static void init({
    Map<String, Map<String, String>>? translations,
    List<Locale>? supported,
    Locale? initialLocale,
    bool followSystem = true,
    bool mergeTranslations = false,
  }) {
    if (_initialized) return;
    _initialized = true;

    if (supported != null && supported.isNotEmpty) {
      _supportedLocales = List.unmodifiable(supported);
    }

    if (translations != null) {
      if (!mergeTranslations) {
        _translations.clear();
        _pluralTemplates.clear();
      }
      translations.forEach((key, map) {
        final normalized = _normalizeLangKey(key);
        _translations[normalized] ??= {};
        _translations[normalized]!.addAll(map);
      });
    }

    _followSystem = followSystem;

    final locale = initialLocale != null ? _resolveLocale(initialLocale) : _getSystemLocale();
    current = locale.obs;

    WidgetsBinding.instance.addObserver(_observer);

    if (followSystem) {
      _syncWithSystem(WidgetsBinding.instance.platformDispatcher.locale);
    }
  }

//   flutter:
//   assets:
//     - assets/i18n/en.json
//     - assets/i18n/zh_cn.json
//     - assets/i18n/zh_tw.json
//     - assets/i18n/ja.json

// 示例 assets/i18n/zh_cn.json
//     {
//   "hello": "你好 {name}",
//   "welcome": "欢迎使用RxLocale"
// }
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // 1.初始化
//   RxLocale.init(followSystem: true);

//   // 2.加载json bundle（可以await）
//   await RxLocale.loadJsonBundles([
//     "assets/i18n/en.json",
//     "assets/i18n/zh_cn.json",
//     "assets/i18n/zh_tw.json",
//     "assets/i18n/ja.json",
//   ]);

//   // 持久化钩子示例，业务接shared_preferences
//   RxLocale.onSaveLocale = (loc) async {
//     final s = RxLocale.localeToString(loc);
//     // await prefs.setString("app_locale", s);
//   };

//   runApp(const MyApp());
// }
  /// 加载单个json翻译资源
  static Future<void> loadJsonBundle(String assetPath, {bool merge = true}) async {
    try {
      final data = await rootBundle.loadString(assetPath);
      final dynamic jsonObj = json.decode(data);
      if (jsonObj is! Map<String, dynamic>) {
        debugPrint('[RxLocale] invalid json format: $assetPath');
        return;
      }
      // final fileName = assetPath.split('/').last;
      // final langKey = fileName.split('.').first;

      final fileName = assetPath.split('/').last;
      final langKey = fileName.contains('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;

      final normKey = _normalizeLangKey(langKey);

      final Map<String, String> normalMap = {};
      final Map<String, String> pluralMap = {};

      jsonObj.forEach((k, v) {
        if (v is! String) return;
        final s = v as String;
        if (s.contains(',plural,')) {
          pluralMap[k] = s;
        } else {
          normalMap[k] = s;
        }
      });

      if (!merge) {
        _translations[normKey] = normalMap;
        _pluralTemplates[normKey] = pluralMap;
      } else {
        _translations[normKey] ??= {};
        _translations[normKey]!.addAll(normalMap);
        _pluralTemplates[normKey] ??= {};
        _pluralTemplates[normKey]!.addAll(pluralMap);
      }
    } catch (e) {
      debugPrint('[RxLocale] loadJsonBundle error $assetPath : $e');
    }
  }

  /// 批量加载json
  static Future<void> loadJsonBundles(List<String> assetPaths, {bool merge = true}) async {
    for (final path in assetPaths) {
      await loadJsonBundle(path, merge: merge);
    }
  }

  static void dispose() {
    if (!_initialized) return;
    WidgetsBinding.instance.removeObserver(_observer);
    _initialized = false;
    _translations.clear();
    _pluralTemplates.clear();
    // 建议补充：
    _followSystem = true;
    onSaveLocale = null;
  }

  static void setLocale(Locale locale) {
    final resolved = _resolveLocale(locale);
    _followSystem = false;

    if (current.value != resolved) {
      current.value = resolved;
    }
    onSaveLocale?.call(resolved);
  }

  static void followSystem() {
    _followSystem = true;
    _syncWithSystem(WidgetsBinding.instance.platformDispatcher.locale);
  }

  static bool get isManual => !_followSystem;

  static Locale _getSystemLocale() {
    final system = WidgetsBinding.instance.platformDispatcher.locale;
    return _resolveLocale(system);
  }

  static Locale _resolveLocale(Locale system) {
    for (final locale in _supportedLocales) {
      if (locale.languageCode == system.languageCode && locale.countryCode == system.countryCode) {
        return locale;
      }
    }
    for (final locale in _supportedLocales) {
      if (locale.languageCode == system.languageCode) {
        return locale;
      }
    }
    return _supportedLocales.isNotEmpty ? _supportedLocales.first : const Locale('en');
  }

  static void _syncWithSystem(Locale systemLocale) {
    final locale = _resolveLocale(systemLocale);
    if (current.value != locale) {
      current.value = locale;
    }
  }

  /// 普通翻译
  static String tr(
    String key, {
    Map<String, String>? params,
  }) {
    final rawLangKey = locale.countryCode != null && locale.countryCode!.isNotEmpty ? '${locale.languageCode}_${locale.countryCode}' : locale.languageCode;
    final langKey = _normalizeLangKey(rawLangKey); // 归一化为小写

    String text = _translations[langKey]?[key] ?? _translations[locale.languageCode.toLowerCase()]?[key] ?? _translations['en']?[key] ?? key;

    if (params != null) {
      for (final entry in params.entries) {
        text = text.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return text;
  }

  /// 复数翻译
  static String trPlural(
    String key,
    num count, {
    Map<String, String>? params,
  }) {
    final locale = current.value;
    final rawLangKey = locale.countryCode != null && locale.countryCode!.isNotEmpty ? '${locale.languageCode}_${locale.countryCode}' : locale.languageCode;
    final langKey = _normalizeLangKey(rawLangKey);
    final langOnly = _normalizeLangKey(locale.languageCode);

    String? template = _pluralTemplates[langKey]?[key] ?? _pluralTemplates[langOnly]?[key] ?? _pluralTemplates['en']?[key];

    // 1. 如果复数模板不存在，降级尝试普通翻译，注入count参数
    if (template == null) {
      final fallbackParams = <String, String>{
        'count': '$count',
        ...?params,
      };
      return tr(key, params: fallbackParams);
    }

    // 2. 解析复数分支
    String evalResult = _evalPluralTemplate(template, count);
    // 解析结果为空直接返回key，避免输出空白
    if (evalResult.isEmpty) return key;

    // 3. 替换占位：params中的count优先，用于自定义格式化展示文本
    final countStr = params?['count'] ?? '$count';
    String out = evalResult.replaceAll('{count}', countStr);

    if (params != null) {
      for (final e in params.entries) {
        if (e.key == 'count') continue; // count已完成替换，跳过
        out = out.replaceAll('{${e.key}}', e.value);
      }
    }
    return out;
  }

  /// 极简plural模板解析，格式："{count,plural,=0{无}=1{一个}other{{count}个}}"
  static String _evalPluralTemplate(String template, num count) {
    const prefix = '{count,plural,';
    if (!template.startsWith(prefix)) return template;
    final inner = template.substring(prefix.length, template.length - 1);

    // final RegExp branchRe = RegExp(r'(=(?<eq>\d+)|zero|one|two|few|many|other)\{(?<val>[^{}]*(?:\{[^{}]*\}[^{}]*)*)\}');
    final RegExp branchRe = RegExp(
      r'(=(?<eq>-?\d+)|zero|one|two|few|many|other)\s*\{(?<val>[^{}]*(?:\{[^{}]*\}[^{}]*)*)\}',
    );
    final matches = branchRe.allMatches(inner);

    String? otherCase;
    String? selected;

    for (final m in matches) {
      final label = m.group(0)!.split('{').first.trim();
      final content = m.namedGroup('val') ?? '';
      if (label == 'other') {
        otherCase = content;
        continue;
      }
      if (label.startsWith('=')) {
        final eqVal = int.tryParse(label.substring(1));
        if (eqVal == count) {
          selected = content;
          break;
        }
      }
      if (label == 'one' && count == 1) {
        selected = content;
        break;
      }
      if (label == 'zero' && count == 0) {
        selected = content;
        break;
      }
    }
    return selected ?? otherCase ?? '';
  }

  static Locale get locale => current.value;

  // 序列化，用于持久化
  static String localeToString(Locale loc) {
    if (loc.countryCode != null && loc.countryCode!.isNotEmpty) {
      return '${loc.languageCode}_${loc.countryCode}';
    }
    return loc.languageCode;
  }

  static Locale? localeFromString(String str) {
    final parts = str.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(str);
  }

  static String _normalizeLangKey(String raw) {
    return raw.replaceAll('-', '_').toLowerCase();
  }
}

extension RxLocaleExt on String {
  String get tr => RxLocale.tr(this);

  String trParams(Map<String, String> params) => RxLocale.tr(this, params: params);

  String trPlural(num count, {Map<String, String>? params}) => RxLocale.trPlural(this, count, params: params);
}
