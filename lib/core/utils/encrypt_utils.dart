import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// AES-256-GCM 备份加密（PBKDF2 派生密钥）
class EncryptUtils {
  EncryptUtils._();

  static const _magic = 'EZBKBK1';
  static const _magicLength = 7;
  static const _saltLength = 16;
  static const _nonceLength = 12;
  static const _macLength = 16;

  static final AesGcm _algorithm = AesGcm.with256bits();
  static final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 120000,
    bits: 256,
  );

  static Future<Uint8List> encryptBytes(
    Uint8List plainText,
    String password,
  ) async {
    final salt = _randomBytes(_saltLength);
    final secretKey = await _deriveKey(password, salt);
    final nonce = _randomBytes(_nonceLength);
    final secretBox = await _algorithm.encrypt(
      plainText,
      secretKey: secretKey,
      nonce: nonce,
    );

    final builder = BytesBuilder();
    builder.add(utf8.encode(_magic));
    builder.add(salt);
    builder.add(secretBox.nonce);
    builder.add(secretBox.cipherText);
    builder.add(secretBox.mac.bytes);
    return builder.toBytes();
  }

  static Future<Uint8List> decryptBytes(
    Uint8List cipherData,
    String password,
  ) async {
    const minLength = _magicLength + _saltLength + _nonceLength + _macLength;
    if (cipherData.length < minLength) {
      throw const FormatException('无效的加密备份文件');
    }

    final magic = utf8.decode(cipherData.sublist(0, _magicLength));
    if (magic != _magic) {
      throw const FormatException('无效的加密备份文件');
    }

    final salt = cipherData.sublist(_magicLength, _magicLength + _saltLength);
    final nonceStart = _magicLength + _saltLength;
    final nonce = cipherData.sublist(nonceStart, nonceStart + _nonceLength);
    final mac = Mac(cipherData.sublist(cipherData.length - _macLength));
    final cipherText = cipherData.sublist(
      nonceStart + _nonceLength,
      cipherData.length - _macLength,
    );

    final secretKey = await _deriveKey(password, salt);
    final box = SecretBox(cipherText, nonce: nonce, mac: mac);
    return Uint8List.fromList(
      await _algorithm.decrypt(box, secretKey: secretKey),
    );
  }

  static Future<String> encrypt(String plainText, String password) async {
    final bytes = await encryptBytes(Uint8List.fromList(utf8.encode(plainText)), password);
    return base64Encode(bytes);
  }

  static Future<String> decrypt(String cipherText, String password) async {
    final bytes = await decryptBytes(base64Decode(cipherText), password);
    return utf8.decode(bytes);
  }

  static Future<SecretKey> _deriveKey(String password, List<int> salt) {
    return _pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}
