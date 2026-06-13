import 'package:flutter_test/flutter_test.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/services/alipay_type_resolver.dart';

void main() {
  test('识别不计收支', () {
    expect(
      AlipayTypeResolver.resolve(typeText: '不计收支', categoryName: '投资理财'),
      TransactionType.transfer,
    );
  });

  test('其它类型结合投资理财按转账导入', () {
    expect(
      AlipayTypeResolver.resolve(typeText: '其它', categoryName: '投资理财'),
      TransactionType.transfer,
    );
  });

  test('收支柱空时按交易分类推断转账', () {
    expect(
      AlipayTypeResolver.resolve(typeText: null, categoryName: '投资理财'),
      TransactionType.transfer,
    );
  });

  test('商业服务其它不入账', () {
    expect(
      AlipayTypeResolver.resolve(typeText: '其它', categoryName: '商业服务'),
      isNull,
    );
  });

  test('支出且转账红包按不计收支导入', () {
    expect(
      AlipayTypeResolver.resolve(
        typeText: '支出',
        categoryName: '转账红包',
        status: '支付成功',
      ),
      TransactionType.transfer,
    );
  });

  test('支出且商业服务仍为支出', () {
    expect(
      AlipayTypeResolver.resolve(
        typeText: '支出',
        categoryName: '商业服务',
        status: '支付成功',
      ),
      TransactionType.expense,
    );
  });

  test('微信中性收支柱按转账导入', () {
    expect(
      AlipayTypeResolver.resolve(
        typeText: '/',
        categoryName: '零钱通',
        status: '支付成功',
      ),
      TransactionType.transfer,
    );
  });
}
