import 'dart:convert';
import 'dart:io';

import 'package:gbk_codec/gbk_codec.dart';

/// 从内存字节解码文本（文件选择器直读，避免中文路径读失败）。
String decodeTextBytes(
  List<int> bytes, {
  String encoding = 'auto',
}) {
  if (bytes.isEmpty) return '';

  if (encoding == 'gbk') {
    return gbk_bytes.decode(bytes);
  }

  if (encoding != 'auto') {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3));
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    return utf8.decode(bytes.sublist(3));
  }

  final utf8Text = utf8.decode(bytes, allowMalformed: true);
  final gbkText = gbk_bytes.decode(bytes);
  final utf8CjkCount = _countCjkCharacters(utf8Text);
  final gbkCjkCount = _countCjkCharacters(gbkText);

  if (utf8Text.contains('\uFFFD') || gbkCjkCount > utf8CjkCount) {
    return gbkText;
  }
  return utf8Text;
}

/// 按指定编码读取文本文件；[encoding] 为 `auto` 时自动识别。
Future<String> readTextFileWithEncoding(
  String filePath, {
  String encoding = 'auto',
}) async {
  if (encoding == 'auto') {
    return readTextFileAutoEncoding(filePath);
  }

  final bytes = await File(filePath).readAsBytes();
  return decodeTextBytes(bytes, encoding: encoding);
}

/// 读取文本文件，自动识别 UTF-8（含 BOM）与 GBK/GB18030（支付宝等导出常用）。
Future<String> readTextFileAutoEncoding(String filePath) async {
  final bytes = await File(filePath).readAsBytes();
  return decodeTextBytes(bytes);
}

int _countCjkCharacters(String text) {
  var count = 0;
  for (final codeUnit in text.codeUnits) {
    if (codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) {
      count++;
    }
  }
  return count;
}
