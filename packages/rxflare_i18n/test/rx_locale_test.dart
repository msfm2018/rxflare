import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxflare_i18n/rxflare_i18n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
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
        followSystem: false,
      );

      expect(RxLocale.locale, const Locale('zh', 'TW'));
      expect(RxLocale.tr('hello'), '你好');
    });

    test('falls back to English when locale is missing', () {
      RxLocale.init(
        supported: const [
          Locale('en'),
          Locale('zh'),
          Locale('ja'),
        ],
        translations: {
          'en': {'welcome': 'Welcome'},
          'zh': {'welcome': '欢迎'},
        },
        initialLocale: const Locale('fr'),
        followSystem: false,
      );

      expect(RxLocale.locale, const Locale('en'));
      expect(RxLocale.tr('welcome'), 'Welcome');
    });

    test('replaces params in normal translations', () {
      RxLocale.init(
        supported: const [Locale('en')],
        translations: {
          'en': {
            'greet': 'Hello {name}, count={count}',
          },
        },
        initialLocale: const Locale('en'),
        followSystem: false,
      );

      expect(
        RxLocale.tr(
          'greet',
          params: {
            'name': 'Ada',
            'count': '3',
          },
        ),
        'Hello Ada, count=3',
      );
    });

    test('supports plural templates and count replacement', () {
      RxLocale.init(
        supported: const [Locale('en')],
        translations: {
          'en': {
            'items':
                '{count,plural,=0{No items}=1{One item}other{{count} items}}',
          },
        },
        initialLocale: const Locale('en'),
        followSystem: false,
      );

      expect(RxLocale.trPlural('items', 0), 'No items');
      expect(RxLocale.trPlural('items', 1), 'One item');
      expect(RxLocale.trPlural('items', 3), '3 items');

      expect(
        RxLocale.trPlural(
          'items',
          5,
          params: {'count': '99'},
        ),
        '99 items',
      );
    });

    test('normalizes locale keys from hyphenated names', () {
      RxLocale.init(
        supported: const [
          Locale('zh', 'CN'),
          Locale('en'),
        ],
        translations: {
          'zh_cn': {'hello': '你好'},
          'en': {'hello': 'Hello'},
        },
        initialLocale: const Locale('zh', 'CN'),
        followSystem: false,
      );

      expect(RxLocale.tr('hello'), '你好');
    });

    test('setLocale updates current locale and disables followSystem', () {
      RxLocale.init(
        supported: const [
          Locale('en'),
          Locale('ja'),
          Locale('zh'),
        ],
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
          'en': {
            'hello': 'Hello',
            'farewell': 'Bye',
          },
        },
        initialLocale: const Locale('en'),
        followSystem: false,
      );

      // 不要在这里调用 RxLocale.dispose()。
      // dispose 会清空已有翻译，无法验证合并行为。

      RxLocale.init(
        translations: {
          'en': {
            'hello': 'Hi',
          },
        },
        mergeTranslations: true,
      );

      expect(RxLocale.tr('hello'), 'Hi');
      expect(RxLocale.tr('farewell'), 'Bye');
    });

    test('localeFromString parses underscore and hyphen formats', () {
      expect(
        RxLocale.localeFromString('zh_CN'),
        const Locale('zh', 'CN'),
      );

      expect(
        RxLocale.localeFromString('zh-CN'),
        const Locale('zh', 'CN'),
      );

      expect(
        RxLocale.localeFromString('en'),
        const Locale('en'),
      );
    });

    test(
      'trPlural falls back to plain translation when plural template is absent',
      () {
        RxLocale.init(
          supported: const [Locale('en')],
          translations: {
            'en': {
              'items': 'Items: {count}',
            },
          },
          initialLocale: const Locale('en'),
          followSystem: false,
        );

        expect(RxLocale.trPlural('items', 2), 'Items: 2');
      },
    );

    test(
      'loadJsonBundle parses valid JSON and ignores invalid values',
      () async {
        final tempDir = await Directory.systemTemp.createTemp();

        final file = File('${tempDir.path}/zh_cn.json');

        await file.writeAsString('''
{
  "hello": "你好 {name}",
  "items": "{count,plural,=0{没有}=1{一个}other{{count} 个}}",
  "invalid": 123
}
''');

        final fakeBundle = _TestAssetBundle({
          file.path: file.readAsStringSync(),
        });

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler(
          'flutter/assets',
          fakeBundle.handle,
        ); // ignore: invalid_use_of_protected_member

        try {
          RxLocale.init(
            supported: const [Locale('zh', 'CN')],
            translations: {
              'zh_cn': {
                'hello': '默认值',
              },
            },
            initialLocale: const Locale('zh', 'CN'),
            followSystem: false,
          );

          await RxLocale.loadJsonBundle(file.path, merge: true);

          expect(
            RxLocale.tr(
              'hello',
              params: {'name': '世界'},
            ),
            '你好 世界',
          );

          expect(
            RxLocale.trPlural('items', 2),
            '2 个',
          );
        } finally {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMessageHandler(
            'flutter/assets',
            null,
          );

          await tempDir.delete(recursive: true);
        }
      },
    );
  });
}

class _TestAssetBundle {
  _TestAssetBundle(this._files);

  final Map<String, String> _files;

  Future<ByteData?> handle(ByteData? message) async {
    if (message == null) {
      throw FlutterError('Asset message is null');
    }

    final encodedKey = utf8.decode(
      message.buffer.asUint8List(
        message.offsetInBytes,
        message.lengthInBytes,
      ),
    );

    // Flutter 在 Windows 下可能会对资源路径进行 URI 编码。
    final decodedKey = Uri.decodeComponent(encodedKey);

    final asset = _files[encodedKey] ?? _files[decodedKey];

    if (asset == null) {
      throw FlutterError(
        'Missing asset: $encodedKey (decoded: $decodedKey)',
      );
    }

    final bytes = Uint8List.fromList(
      utf8.encode(asset),
    );

    return ByteData.sublistView(bytes);
  }
}
