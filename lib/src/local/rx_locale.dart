import 'package:flutter/material.dart';
import 'package:rxflare/src/core/rx_core.dart';

class RxLocale {
  /// 当前语言（自动跟随系统）
  static final current = _getSystemLocale().obs;

  /// 翻译表
  static final Map<String, Map<String, String>> _translations = {};

  /// 支持的语言列表（可选，用于 fallback）
 static List<Locale> supportedLocales = const [
  // ==================== 英语 ====================
  Locale('en'),
  Locale('en', 'US'), // 美国
  Locale('en', 'GB'), // 英国
  Locale('en', 'AU'), // 澳大利亚
  Locale('en', 'CA'), // 加拿大
  Locale('en', 'NZ'), // 新西兰
  Locale('en', 'IE'), // 爱尔兰
  Locale('en', 'ZA'), // 南非
  Locale('en', 'IN'), // 印度
  Locale('en', 'SG'), // 新加坡
  Locale('en', 'PH'), // 菲律宾

  // ==================== 中文 ====================
  Locale('zh'),
  Locale('zh', 'CN'), // 中国大陆（简体）
  Locale('zh', 'TW'), // 台湾（繁体）
  Locale('zh', 'HK'), // 香港（繁体）
  Locale('zh', 'MO'), // 澳门
  Locale('zh', 'SG'), // 新加坡

  // ==================== 日语 ====================
  Locale('ja'),
  Locale('ja', 'JP'),

  // ==================== 韩语 ====================
  Locale('ko'),
  Locale('ko', 'KR'),
  Locale('ko', 'KP'),

  // ==================== 德语 ====================
  Locale('de'),
  Locale('de', 'DE'), // 德国
  Locale('de', 'AT'), // 奥地利
  Locale('de', 'CH'), // 瑞士
  Locale('de', 'LI'), // 列支敦士登
  Locale('de', 'LU'), // 卢森堡

  // ==================== 法语 ====================
  Locale('fr'),
  Locale('fr', 'FR'), // 法国
  Locale('fr', 'CA'), // 加拿大
  Locale('fr', 'BE'), // 比利时
  Locale('fr', 'CH'), // 瑞士
  Locale('fr', 'LU'), // 卢森堡
  Locale('fr', 'MC'), // 摩纳哥

  // ==================== 西班牙语 ====================
  Locale('es'),
  Locale('es', 'ES'), // 西班牙
  Locale('es', 'MX'), // 墨西哥
  Locale('es', 'AR'), // 阿根廷
  Locale('es', 'CO'), // 哥伦比亚
  Locale('es', 'CL'), // 智利
  Locale('es', 'PE'), // 秘鲁
  Locale('es', 'VE'), // 委内瑞拉
  Locale('es', 'EC'), // 厄瓜多尔
  Locale('es', 'GT'), // 危地马拉
  Locale('es', 'CU'), // 古巴
  Locale('es', 'BO'), // 玻利维亚
  Locale('es', 'DO'), // 多米尼加
  Locale('es', 'HN'), // 洪都拉斯
  Locale('es', 'PY'), // 巴拉圭
  Locale('es', 'SV'), // 萨尔瓦多
  Locale('es', 'NI'), // 尼加拉瓜
  Locale('es', 'CR'), // 哥斯达黎加
  Locale('es', 'PA'), // 巴拿马
  Locale('es', 'UY'), // 乌拉圭
  Locale('es', 'PR'), // 波多黎各

  // ==================== 葡萄牙语 ====================
  Locale('pt'),
  Locale('pt', 'PT'), // 葡萄牙
  Locale('pt', 'BR'), // 巴西
  Locale('pt', 'AO'), // 安哥拉
  Locale('pt', 'MZ'), // 莫桑比克

  // ==================== 意大利语 ====================
  Locale('it'),
  Locale('it', 'IT'),
  Locale('it', 'CH'),
  Locale('it', 'SM'),
  Locale('it', 'VA'),

  // ==================== 俄语 ====================
  Locale('ru'),
  Locale('ru', 'RU'),
  Locale('ru', 'BY'),
  Locale('ru', 'KZ'),
  Locale('ru', 'KG'),

  // ==================== 阿拉伯语 ====================
  Locale('ar'),
  Locale('ar', 'SA'), // 沙特
  Locale('ar', 'EG'), // 埃及
  Locale('ar', 'AE'), // 阿联酋
  Locale('ar', 'IQ'), // 伊拉克
  Locale('ar', 'MA'), // 摩洛哥
  Locale('ar', 'DZ'), // 阿尔及利亚
  Locale('ar', 'TN'), // 突尼斯
  Locale('ar', 'LY'), // 利比亚
  Locale('ar', 'JO'), // 约旦
  Locale('ar', 'LB'), // 黎巴嫩
  Locale('ar', 'SY'), // 叙利亚
  Locale('ar', 'YE'), // 也门
  Locale('ar', 'KW'), // 科威特
  Locale('ar', 'QA'), // 卡塔尔
  Locale('ar', 'BH'), // 巴林
  Locale('ar', 'OM'), // 阿曼
  Locale('ar', 'SD'), // 苏丹

  // ==================== 南亚语言 ====================
  Locale('hi'), // 印地语
  Locale('hi', 'IN'),
  Locale('bn'), // 孟加拉语
  Locale('bn', 'BD'),
  Locale('bn', 'IN'),
  Locale('ur'), // 乌尔都语
  Locale('ur', 'PK'),
  Locale('ur', 'IN'),
  Locale('ta'), // 泰米尔语
  Locale('ta', 'IN'),
  Locale('ta', 'LK'),
  Locale('te'), // 泰卢固语
  Locale('te', 'IN'),
  Locale('mr'), // 马拉地语
  Locale('mr', 'IN'),
  Locale('gu'), // 古吉拉特语
  Locale('gu', 'IN'),
  Locale('kn'), // 卡纳达语
  Locale('kn', 'IN'),
  Locale('ml'), // 马拉雅拉姆语
  Locale('ml', 'IN'),
  Locale('pa'), // 旁遮普语
  Locale('pa', 'IN'),
  Locale('pa', 'PK'),
  Locale('or'), // 奥里亚语
  Locale('as'), // 阿萨姆语
  Locale('ne'), // 尼泊尔语
  Locale('si'), // 僧伽罗语
  Locale('si', 'LK'),

  // ==================== 东南亚 ====================
  Locale('th'), // 泰语
  Locale('th', 'TH'),
  Locale('vi'), // 越南语
  Locale('vi', 'VN'),
  Locale('id'), // 印尼语
  Locale('id', 'ID'),
  Locale('ms'), // 马来语
  Locale('ms', 'MY'),
  Locale('ms', 'BN'),
  Locale('ms', 'SG'),
  Locale('fil'), // 菲律宾语
  Locale('fil', 'PH'),
  Locale('km'), // 高棉语
  Locale('lo'), // 老挝语
  Locale('my'), // 缅甸语
  Locale('my', 'MM'),

  // ==================== 欧洲其他 ====================
  Locale('nl'), // 荷兰语
  Locale('nl', 'NL'),
  Locale('nl', 'BE'),
  Locale('pl'), // 波兰语
  Locale('pl', 'PL'),
  Locale('sv'), // 瑞典语
  Locale('sv', 'SE'),
  Locale('sv', 'FI'),
  Locale('da'), // 丹麦语
  Locale('da', 'DK'),
  Locale('fi'), // 芬兰语
  Locale('fi', 'FI'),
  Locale('no'), // 挪威语
  Locale('no', 'NO'),
  Locale('nb'), // 书面挪威语
  Locale('nn'), // 新挪威语
  Locale('cs'), // 捷克语
  Locale('cs', 'CZ'),
  Locale('sk'), // 斯洛伐克语
  Locale('sk', 'SK'),
  Locale('hu'), // 匈牙利语
  Locale('hu', 'HU'),
  Locale('ro'), // 罗马尼亚语
  Locale('ro', 'RO'),
  Locale('ro', 'MD'),
  Locale('uk'), // 乌克兰语
  Locale('uk', 'UA'),
  Locale('el'), // 希腊语
  Locale('el', 'GR'),
  Locale('el', 'CY'),
  Locale('bg'), // 保加利亚语
  Locale('bg', 'BG'),
  Locale('hr'), // 克罗地亚语
  Locale('hr', 'HR'),
  Locale('sr'), // 塞尔维亚语
  Locale('sr', 'RS'),
  Locale('bs'), // 波斯尼亚语
  Locale('sl'), // 斯洛文尼亚语
  Locale('sl', 'SI'),
  Locale('mk'), // 马其顿语
  Locale('sq'), // 阿尔巴尼亚语
  Locale('sq', 'AL'),
  Locale('lt'), // 立陶宛语
  Locale('lt', 'LT'),
  Locale('lv'), // 拉脱维亚语
  Locale('lv', 'LV'),
  Locale('et'), // 爱沙尼亚语
  Locale('et', 'EE'),
  Locale('is'), // 冰岛语
  Locale('is', 'IS'),
  Locale('ga'), // 爱尔兰语
  Locale('ga', 'IE'),
  Locale('mt'), // 马耳他语
  Locale('mt', 'MT'),
  Locale('cy'), // 威尔士语
  Locale('cy', 'GB'),
  Locale('eu'), // 巴斯克语
  Locale('ca'), // 加泰罗尼亚语
  Locale('ca', 'ES'),
  Locale('gl'), // 加利西亚语
  Locale('gl', 'ES'),

  // ==================== 中东 & 中亚 ====================
  Locale('he'), // 希伯来语
  Locale('he', 'IL'),
  Locale('fa'), // 波斯语
  Locale('fa', 'IR'),
  Locale('fa', 'AF'),
  Locale('tr'), // 土耳其语
  Locale('tr', 'TR'),
  Locale('tr', 'CY'),
  Locale('az'), // 阿塞拜疆语
  Locale('az', 'AZ'),
  Locale('kk'), // 哈萨克语
  Locale('kk', 'KZ'),
  Locale('uz'), // 乌兹别克语
  Locale('uz', 'UZ'),
  Locale('ky'), // 吉尔吉斯语
  Locale('ky', 'KG'),
  Locale('tg'), // 塔吉克语
  Locale('tk'), // 土库曼语
  Locale('mn'), // 蒙古语
  Locale('mn', 'MN'),
  Locale('ka'), // 格鲁吉亚语
  Locale('ka', 'GE'),
  Locale('hy'), // 亚美尼亚语
  Locale('hy', 'AM'),
  Locale('ps'), // 普什图语
  Locale('ps', 'AF'),
  Locale('ku'), // 库尔德语

  // ==================== 非洲 ====================
  Locale('sw'), // 斯瓦希里语
  Locale('sw', 'KE'),
  Locale('sw', 'TZ'),
  Locale('am'), // 阿姆哈拉语
  Locale('am', 'ET'),
  Locale('ha'), // 豪萨语
  Locale('yo'), // 约鲁巴语
  Locale('ig'), // 伊博语
  Locale('zu'), // 祖鲁语
  Locale('xh'), // 科萨语
  Locale('af'), // 南非荷兰语
  Locale('af', 'ZA'),
  Locale('st'), // 南索托语
  Locale('tn'), // 茨瓦纳语
  Locale('ts'), // 聪加语
  Locale('ss'), // 斯瓦蒂语
  Locale('ve'), // 文达语
  Locale('nr'), // 南恩德贝莱语
  Locale('nso'), // 北索托语

  // ==================== 其他 ====================
  Locale('eo'), // 世界语
  Locale('la'), // 拉丁语
];

  /// 初始化（建议在 main 里调用一次）
  static void init({
    Map<String, Map<String, String>>? translations,
    List<Locale>? supported,
  }) {
    if (translations != null) {
      _translations.addAll(translations);
    }
    if (supported != null) {
      supportedLocales = supported;
    }

    // 首次同步系统语言
    _syncWithSystem();

    // 监听系统语言变化（用户在系统设置里改语言时自动切换）
    WidgetsBinding.instance.platformDispatcher.onLocaleChanged = () {
      _syncWithSystem();
    };
  }

  /// 获取当前系统 Locale
  static Locale _getSystemLocale() {
    final system = WidgetsBinding.instance.platformDispatcher.locale;
    return _resolveLocale(system);
  }

  /// 解析最匹配的语言（带 fallback）
  static Locale _resolveLocale(Locale system) {
    // 1. 精确匹配 languageCode_countryCode
    for (final locale in supportedLocales) {
      if (locale.languageCode == system.languageCode && locale.countryCode == system.countryCode) {
        return locale;
      }
    }
    // 2. 只匹配 languageCode
    for (final locale in supportedLocales) {
      if (locale.languageCode == system.languageCode) {
        return locale;
      }
    }
    // 3. 默认回退到第一个支持的语言（通常是英文）
    return supportedLocales.isNotEmpty ? supportedLocales.first : const Locale('en');
  }

  /// 同步系统语言
  static void _syncWithSystem() {
    final newLocale = _getSystemLocale();
    if (current.value != newLocale) {
      current.value = newLocale;
    }
  }

  /// 获取翻译
  static String tr(String key, {Map<String, String>? params}) {
    final langKey = current.value.countryCode != null && current.value.countryCode!.isNotEmpty ? '${current.value.languageCode}_${current.value.countryCode}' : current.value.languageCode;

    String? text = _translations[langKey]?[key] ?? _translations[current.value.languageCode]?[key] ?? _translations['en']?[key] ?? key;

    if (params != null) {
      params.forEach((k, v) {
        text = text!.replaceAll('{$k}', v);
      });
    }
    return text!;
  }

  /// 当前 Locale（只读）
  static Locale get locale => current.value;
}

/// 字符串扩展
extension RxLocaleExt on String {
  String get tr => RxLocale.tr(this);

  String trParams(Map<String, String> params) => RxLocale.tr(this, params: params);
}
