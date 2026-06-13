import 'dart:convert';

import 'package:ezbookkeeping_desktop/core/constants/app_constants.dart';

/// 设置项敏感字符串的简单混淆（非强加密，避免明文落盘）。
class SettingsSecrets {
  SettingsSecrets._();

  static String encode(String plain) {
    if (plain.isEmpty) return '';
    final key = utf8.encode('${AppConstants.appName}_v1');
    final bytes = utf8.encode(plain);
    final encoded = List<int>.generate(
      bytes.length,
      (i) => bytes[i] ^ key[i % key.length],
    );
    return base64Encode(encoded);
  }

  static String decode(String stored) {
    if (stored.isEmpty) return '';
    try {
      final key = utf8.encode('${AppConstants.appName}_v1');
      final bytes = base64Decode(stored);
      final plain = List<int>.generate(
        bytes.length,
        (i) => bytes[i] ^ key[i % key.length],
      );
      return utf8.decode(plain);
    } catch (_) {
      return stored;
    }
  }
}
