import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gbk_codec/gbk_codec.dart';
import 'package:ezbookkeeping_desktop/core/utils/text_file_encoding.dart';

void main() {
  test('读取 UTF-8 BOM 文本', () async {
    final file = File('${Directory.systemTemp.path}/utf8_bom_test.csv');
    await file.writeAsBytes([
      0xEF,
      0xBB,
      0xBF,
      ...utf8.encode('日期,类型,金额'),
    ]);

    expect(await readTextFileAutoEncoding(file.path), '日期,类型,金额');
    await file.delete();
  });

  test('读取 GBK 文本', () async {
    final file = File('${Directory.systemTemp.path}/gbk_test.csv');
    await file.writeAsBytes(gbk_bytes.encode('交易时间,收/支,金额'));

    expect(await readTextFileAutoEncoding(file.path), '交易时间,收/支,金额');
    await file.delete();
  });
}
