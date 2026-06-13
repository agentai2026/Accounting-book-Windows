import 'package:flutter_test/flutter_test.dart';
import 'package:ezbookkeeping_desktop/core/services/transaction_import_column_map.dart';

void main() {
  test('识别新版表头', () {
    final map = TransactionImportColumnMap.fromHeaders([
      '日期',
      '类型',
      '金额',
      '分类',
      '账户',
      '付款人',
      '备注',
    ]);

    expect(map.date, 0);
    expect(map.categoryName, 3);
    expect(map.account, 4);
    expect(map.payer, 5);
    expect(map.remark, 6);
  });

  test('兼容旧版分类ID表头', () {
    final map = TransactionImportColumnMap.fromHeaders([
      '日期',
      '类型',
      '金额',
      '分类ID',
      '备注',
    ]);

    expect(map.categoryId, 3);
    expect(map.remark, 4);
    expect(map.categoryName, isNull);
  });

  test('识别支付宝账单表头', () {
    final map = TransactionImportColumnMap.fromHeaders([
      '交易时间',
      '交易分类',
      '交易对方',
      '对方账号',
      '商品说明',
      '收/支',
      '金额',
      '收/付款方式',
      '交易状态',
      '交易订单号',
      '商家订单号',
      '备注',
    ]);

    expect(map.date, 0);
    expect(map.type, 5);
    expect(map.amount, 6);
    expect(map.categoryName, 1);
    expect(map.payer, 2);
    expect(map.account, 7);
    expect(map.status, 8);
    expect(map.remark, 11);
    expect(map.refundAmount, isNull);
  });

  test('识别支付宝流水证明表头', () {
    final map = TransactionImportColumnMap.fromHeaders([
      '交易号',
      '商家订单号',
      '交易创建时间',
      '付款时间',
      '最近修改时间',
      '交易来源地',
      '类型',
      '交易对方',
      '商品名称',
      '金额（元）',
      '收/支',
      '交易状态',
      '服务费（元）',
      '成功退款（元）',
      '备注',
      '资金状态',
    ]);

    expect(map.date, 3);
    expect(map.type, 10);
    expect(map.amount, 9);
    expect(map.payer, 7);
    expect(map.remark, 14);
    expect(map.status, 11);
    expect(map.refundAmount, 13);
  });

  test('读取单元格', () {
    final map = TransactionImportColumnMap.fromHeaders([
      '日期',
      '类型',
      '金额',
      '备注',
    ]);

    expect(
      map.cell(['2026/06/10 12:00', '支出', '35.00', '午餐'], map.remark),
      '午餐',
    );
  });
}
