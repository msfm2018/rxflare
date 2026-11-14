import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:rxflare_i18n/rxflare_i18n.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    RxLocale.dispose();
  });

  tearDown(() {
    RxLocale.dispose();
  });

  group('RxLocale', () {
    test('resolves exact locale and falls back to language match', () {
      RxLocale.init(
        supported: const [
          Locale('en'),
          Locale('zh'),
          Locale('zh', 'CN'),
          Locale('zh', 'TW'),
        ],
        translations: {
          'en': {'hello': 'Hello'},
          'zh': {'hello': '你好'},
        },
        initialLocale: const Locale('zh', 'TW'),
      );

      expect(RxLocale.locale, const Locale('zh', 'TW'));
      expect(RxLocale.tr('hello'), '你好');
    });

    test('falls back to English when locale is missing', () {
      RxLocale.init(
        supported: const [Locale('en'), Locale('zh'), Locale('ja')],
        translations: {
          'en': {'welcome': 'Welcome'},
          'zh': {'welcome': '欢迎'},
        },
        initialLocale: const Locale('fr'),
      );

      expect(RxLocale.locale, const Locale('en'));
      expect(RxLocale.tr('welcome'), 'Welcome');
    });

    test('replaces params in normal translations', () {
      RxLocale.init(
        supported: const [Locale('en')],
        translations: {
          'en': {'greet': 'Hello {name}, count={count}'},
        },
        initialLocale: const Locale('en'),
      );

      expect(
        RxLocale.tr('greet', params: {'name': 'Ada', 'count': '3'}),
        'Hello Ada, count=3',
      );
    });

    test('supports plural templates and count replacement', () {
      RxLocale.init(
        supported: const [Locale('en')],
        translations: {
          'en': {
            'items': '{count,plural,=0{No items}=1{One item}other{{count} items}}',
          },
        },
        initialLocale: const Locale('en'),
      );

      expect(RxLocale.trPlural('items', 0), 'No items');
      expect(RxLocale.trPlural('items', 1), 'One item');
      expect(RxLocale.trPlural('items', 3), '3 items');
      expect(
        RxLocale.trPlural('items', 5, params: {'count': '99'}),
        '99 items',
      );
    });

    test('normalizes locale keys from hyphenated names', () {
      RxLocale.init(
        supported: const [Locale('zh', 'CN'), Locale('en')],
        translations: {
          'zh_cn': {'hello': '你好'},
          'en': {'hello': 'Hello'},
        },
        initialLocale: const Locale('zh', 'CN'),
      );

      expect(RxLocale.tr('hello'), '你好');
    });

    test('setLocale updates current locale and disables followSystem', () {
      RxLocale.init(
        supported: const [Locale('en'), Locale('ja'), Locale('zh')],
        translations: {
          'en': {'hello': 'Hello'},
          'ja': {'hello': 'こんにちは'},
        },
        initialLocale: const Locale('en'),
        followSystem: true,
      );

      RxLocale.setLocale(const Locale('ja'));

      expect(RxLocale.locale, const Locale('ja'));
      expect(RxLocale.isManual, isTrue);
      expect(RxLocale.isFollowingSystem, isFalse);
      expect(RxLocale.tr('hello'), 'こんにちは');
    });

    test('init supports mergeTranslations mode', () {
      RxLocale.init(
        supported: const [Locale('en')],
        translations: {
          'en': {'hello': 'Hello', 'farewell': 'Bye'},
        },
        initialLocale: const Locale('en'),
      );

      RxLocale.dispose();

      RxLocale.init(
        supported: const [Locale('en')],
        translations: {
          'en': {'hello': 'Hi'},
        },
        initialLocale: const Locale('en'),
        mergeTranslations: true,
      );

      expect(RxLocale.tr('hello'), 'Hi');
      expect(RxLocale.tr('farewell'), 'Bye');
    });
  });
}
