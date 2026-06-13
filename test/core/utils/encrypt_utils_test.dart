import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:ezbookkeeping_desktop/core/utils/encrypt_utils.dart';

void main() {
  test('encryptBytes roundtrip preserves payload', () async {
    const password = 'backup-pass-123456';
    final plain = Uint8List.fromList(List<int>.generate(256, (i) => i % 256));

    final encrypted = await EncryptUtils.encryptBytes(plain, password);
    final decrypted = await EncryptUtils.decryptBytes(encrypted, password);

    expect(decrypted, plain);
  });

  test('decryptBytes fails with wrong password', () async {
    const password = 'correct-password-123';
    final plain = Uint8List.fromList([1, 2, 3, 4, 5]);
    final encrypted = await EncryptUtils.encryptBytes(plain, password);

    await expectLater(
      EncryptUtils.decryptBytes(encrypted, 'wrong-password-123'),
      throwsA(isA<Exception>()),
    );
  });

  test('encrypt/decrypt string helpers roundtrip', () async {
    const password = 'secret-123456';
    const text = 'hello ezbookkeeping';

    final cipher = await EncryptUtils.encrypt(text, password);
    final plain = await EncryptUtils.decrypt(cipher, password);

    expect(plain, text);
  });
}
