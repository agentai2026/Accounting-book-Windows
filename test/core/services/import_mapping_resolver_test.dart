import 'package:flutter_test/flutter_test.dart';

import 'package:ezbookkeeping_desktop/core/services/import_column_mapping_config.dart';
import 'package:ezbookkeeping_desktop/core/services/import_mapping_resolver.dart';

void main() {
  final wechatRows = [
  List.filled(8, '微信支付账单明细'),
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
      '商户',
      '备注',
      '支出',
      '14.60',
      '农业银行储蓄卡(6579)',
      '支付成功',
    ],
  ];

  test('自动解析微信账单列映射', () {
    final mapping = ImportMappingResolver.resolve(wechatRows);

    expect(mapping.headerRowIndex, 5);
    expect(mapping.hasRequiredMapping, isTrue);
    expect(mapping.columnFor(ImportColumnField.time), 0);
    expect(mapping.columnFor(ImportColumnField.type), 4);
    expect(mapping.columnFor(ImportColumnField.amount), 5);
    expect(mapping.columnFor(ImportColumnField.status), 7);
  });
}
