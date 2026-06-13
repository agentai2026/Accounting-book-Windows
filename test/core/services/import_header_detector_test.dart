import 'package:flutter_test/flutter_test.dart';

import 'package:ezbookkeeping_desktop/core/services/import_column_mapping_config.dart';
import 'package:ezbookkeeping_desktop/core/services/import_header_detector.dart';
import 'package:ezbookkeeping_desktop/core/services/import_raw_file_reader.dart';

void main() {
  final wechatRows = [
    ['微信支付账单明细'],
    ['微信昵称：测试用户'],
    ['起始时间：[2026-01-01 00:00:00] 终止时间：[2026-02-28 23:59:59]'],
    ['导出类型：全部'],
    ['导出时间：[2026-03-01 10:00:00]'],
    [
      '交易时间',
      '交易类型',
      '交易对方',
      '商品',
      '收/支',
      '金额(元)',
      '支付方式',
      '当前状态',
    ],
    [
      '2026-02-22T01:26:15.000Z',
      '扫二维码付款',
      '勾GOU',
      '收款方备注:二维码收款',
      '支出',
      '1460',
      '农业银行储蓄卡(6579)',
      '支付成功',
    ],
  ];

  test('识别微信账单真实表头行', () {
    expect(ImportHeaderDetector.findHeaderRowIndex(wechatRows), 5);
    expect(ImportRawFileReader.findHeaderRowIndex(wechatRows), 5);
    expect(ImportHeaderDetector.isTitlePreambleRow(wechatRows.first), isTrue);
  });

  test('微信账单表头自动映射列', () {
    final mapping = ImportColumnMappingConfig.autoDetect(
      rows: wechatRows,
      headerRowIndex: 5,
    );

    expect(mapping.hasRequiredMapping, isTrue);
    expect(mapping.columnFor(ImportColumnField.time), 0);
    expect(mapping.columnFor(ImportColumnField.type), 4);
    expect(mapping.columnFor(ImportColumnField.amount), 5);
    expect(mapping.columnFor(ImportColumnField.payer), 2);
    expect(mapping.columnFor(ImportColumnField.account), 6);
    expect(mapping.columnFor(ImportColumnField.status), 7);
    expect(mapping.columnFor(ImportColumnField.remark), 3);
  });

  test('合并单元格标题行不会误判为表头', () {
    final mergedTitle = List.filled(8, '微信支付账单明细');
  final rows = [
      mergedTitle,
      ...wechatRows.skip(1),
    ];
    expect(ImportHeaderDetector.isTitlePreambleRow(mergedTitle), isTrue);
    expect(ImportRawFileReader.findHeaderRowIndex(rows), 5);
  });
}
