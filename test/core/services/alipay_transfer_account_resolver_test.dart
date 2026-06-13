import 'package:flutter_test/flutter_test.dart';
import 'package:ezbookkeeping_desktop/core/services/alipay_transfer_account_resolver.dart';

void main() {
  test('余额宝转出推断账户', () {
    final result = AlipayTransferAccountResolver.resolve(
      paymentMethod: '余额宝',
      categoryName: '投资理财',
      remark: '余额宝-转出到银行卡',
    );

    expect(result.from, '余额宝');
    expect(result.to, '银行卡');
  });

  test('花呗还款推断账户', () {
    final result = AlipayTransferAccountResolver.resolve(
      paymentMethod: '支付宝',
      remark: '花呗主动还款',
    );

    expect(result.from, '支付宝');
    expect(result.to, '花呗');
  });
}
