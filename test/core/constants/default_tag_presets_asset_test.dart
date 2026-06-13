import 'package:flutter_test/flutter_test.dart';

import 'package:ezbookkeeping_desktop/core/constants/default_tag_presets.dart';

/// 校验打包资源：10000 条且不重复（需 flutter test 加载真实 assets）
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('asset has 10000 unique preset tags', () async {
    await DefaultTagPresets.ensureLoaded();
    expect(DefaultTagPresets.count, 10000);
    expect(
      DefaultTagPresets.names.map((name) => name.toLowerCase()).toSet().length,
      10000,
    );
    for (final name in DefaultTagPresets.names) {
      expect(name.length, lessThanOrEqualTo(20));
      expect(name.trim(), name);
    }
  });
}
