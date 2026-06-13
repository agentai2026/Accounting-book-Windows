import 'package:flutter_test/flutter_test.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/services/transaction_import_amount_resolver.dart';

void main() {
  test('支出扣除成功退款后按净额入账', () {
    final result = TransactionImportAmountResolver.resolve(
      type: TransactionType.expense,
      amountText: '500.00',
      refundText: '309.50',
    );

    expect(result?.type, TransactionType.expense);
    expect(result?.amountCents, 19050);
  });

  test('空金额按 0 元入账', () {
    final result = TransactionImportAmountResolver.resolve(
      type: TransactionType.transfer,
      amountText: null,
    );

    expect(result?.amountCents, 0);
  });

  test('全额退款按 0 元入账', () {
    final result = TransactionImportAmountResolver.resolve(
      type: TransactionType.expense,
      amountText: '100.00',
      refundText: '100.00',
    );

    expect(result?.type, TransactionType.expense);
    expect(result?.amountCents, 0);
  });

  test('负数支出按退款收入入账', () {
    final result = TransactionImportAmountResolver.resolve(
      type: TransactionType.expense,
      amountText: '-50.00',
    );

    expect(result?.type, TransactionType.income);
    expect(result?.amountCents, 5000);
  });
}
