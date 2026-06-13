import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoneyUtils', () {
    test('format 分转元', () {
      expect(MoneyUtils.format(10000), '¥100.00');
      expect(MoneyUtils.format(99), '¥0.99');
    });

    test('formatWithSign 支出收入', () {
      expect(
        MoneyUtils.formatWithSign(5000, isExpense: true),
        '-¥50.00',
      );
      expect(
        MoneyUtils.formatWithSign(5000, isIncome: true),
        '+¥50.00',
      );
    });

    test('parseToCents 元转分', () {
      expect(MoneyUtils.parseToCents('100.00'), 10000);
      expect(MoneyUtils.parseToCents('0.99'), 99);
    });

    test('多币种符号', () {
      expect(MoneyUtils.format(100, currencyCode: 'USD'), r'$1.00');
      expect(MoneyUtils.format(100, currencyCode: 'EUR'), '€1.00');
    });
  });
}
