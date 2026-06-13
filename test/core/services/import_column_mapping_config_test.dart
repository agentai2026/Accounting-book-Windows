import 'package:flutter_test/flutter_test.dart';
import 'package:ezbookkeeping_desktop/core/services/import_column_mapping_config.dart';

void main() {
  test('autoDetect 可写入列映射', () {
    final config = ImportColumnMappingConfig.autoDetect(
      rows: const [
        ['交易时间', '收/支', '金额', '交易分类'],
        ['2026/01/01 12:00', '支出', '10.00', '餐饮'],
      ],
      headerRowIndex: 0,
    );

    expect(config.hasRequiredMapping, isTrue);
    expect(config.columnFor(ImportColumnField.time), 0);
    expect(config.columnFor(ImportColumnField.type), 1);
    expect(config.columnFor(ImportColumnField.amount), 2);
  });

  test('autoDetect 微信账单优先映射收/支而非交易类型', () {
    final config = ImportColumnMappingConfig.autoDetect(
      rows: const [
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
          '2026/01/01 12:00',
          '商户消费',
          '美团',
          '午餐',
          '支出',
          '35.00',
          '零钱',
          '支付成功',
        ],
      ],
      headerRowIndex: 0,
    );

    expect(config.columnFor(ImportColumnField.type), 4);
    expect(config.columnFor(ImportColumnField.status), 7);
  });
}
