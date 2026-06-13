import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ezbookkeeping_desktop/core/constants/default_tag_presets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = const StringCodec().decodeMessage(message);
      if (key == DefaultTagPresets.assetPath) {
        return const StandardMessageCodec().encodeMessage(
          '报销\n餐饮\n北京餐饮\n上海外卖\n',
        );
      }
      return null;
    });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  test('loads presets without duplicates', () async {
    await DefaultTagPresets.ensureLoaded();
    expect(DefaultTagPresets.count, 4);
    expect(DefaultTagPresets.names.toSet().length, 4);
  });

  test('search prefers prefix matches', () async {
    await DefaultTagPresets.ensureLoaded();
    final results = DefaultTagPresets.search('餐', limit: 8);
    expect(results.first, '餐饮');
    expect(results, contains('北京餐饮'));
  });
}
