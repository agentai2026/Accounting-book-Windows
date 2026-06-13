import 'package:flutter_test/flutter_test.dart';
import 'package:ezbookkeeping_desktop/core/constants/bookkeeping_metrics_rules.dart';

void main() {
  test('交易关闭不入账', () {
    expect(
      BookkeepingMetricsRules.shouldImportRow(
        direction: '支出',
        status: '交易关闭',
        categoryName: '餐饮美食',
      ),
      isFalse,
    );
  });

  test('不计收支可入账', () {
    expect(
      BookkeepingMetricsRules.shouldImportRow(
        direction: '不计收支',
        status: '交易成功',
        categoryName: '投资理财',
      ),
      isTrue,
    );
  });

  test('微信中性交易可入账', () {
    expect(
      BookkeepingMetricsRules.shouldImportRow(
        direction: '/',
        status: '支付成功',
        categoryName: '零钱通',
      ),
      isTrue,
    );
  });

  test('微信提现已到账可入账', () {
    expect(
      BookkeepingMetricsRules.shouldImportRow(
        direction: '支出',
        status: '提现已到账',
        categoryName: '提现',
      ),
      isTrue,
    );
  });

  test('微信支付成功状态可入账', () {
    expect(
      BookkeepingMetricsRules.shouldImportRow(
        direction: '支出',
        status: '支付成功',
        categoryName: '餐饮美食',
      ),
      isTrue,
    );
  });

  test('无交易状态列时按收支柱入账', () {
    expect(
      BookkeepingMetricsRules.shouldImportRow(
        direction: '支出',
        status: null,
        categoryName: '食品',
      ),
      isTrue,
    );
    expect(
      BookkeepingMetricsRules.shouldImportRow(
        direction: '收入',
        status: '',
        categoryName: '转账红包',
      ),
      isTrue,
    );
  });

  test('退款成功不入账', () {
    expect(
      BookkeepingMetricsRules.shouldImportRow(
        direction: '收入',
        status: '退款成功',
        categoryName: '餐饮美食',
      ),
      isFalse,
    );
  });

  test('净转账规则', () {
    expect(
      BookkeepingMetricsRules.countsAsNetTransfer(
        categoryName: '转账红包',
        direction: '支出',
        status: '交易成功',
      ),
      isTrue,
    );
    expect(
      BookkeepingMetricsRules.countsAsNetTransfer(
        categoryName: '投资理财',
        direction: '不计收支',
        status: '交易成功',
      ),
      isFalse,
    );
  });

  test('储蓄率无收入时为 null', () {
    expect(
      BookkeepingMetricsRules.calcSavingsRate(incomeCents: 0, netCents: -100),
      isNull,
    );
  });
}
