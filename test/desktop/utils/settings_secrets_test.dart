import 'package:flutter_test/flutter_test.dart';

import 'package:ezbookkeeping_desktop/desktop/utils/settings_secrets.dart';

void main() {
  test('encode/decode roundtrip', () {
    const password = 'my-backup-pass-123456';
    final encoded = SettingsSecrets.encode(password);
    expect(encoded, isNot(equals(password)));
    expect(SettingsSecrets.decode(encoded), password);
  });

  test('decode empty returns empty', () {
    expect(SettingsSecrets.decode(''), '');
  });
}
