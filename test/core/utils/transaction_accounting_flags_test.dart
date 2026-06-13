import 'package:flutter_test/flutter_test.dart';
import 'package:ezbookkeeping_desktop/core/constants/transaction_flag_tags.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/transaction.dart';
import 'package:ezbookkeeping_desktop/core/utils/transaction_accounting_flags.dart';

Transaction _expense({String? comment}) {
  final now = DateTime(2026, 6, 10);
  return Transaction(
    uuid: 'u1',
    bookId: 1,
    type: TransactionType.expense,
    amount: 1000,
    categoryId: 5,
    date: now,
    comment: comment,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('标签「不计入收支」排除收支统计', () {
    final t = _expense();
    expect(
      TransactionAccountingFlags.excludesFromIncomeExpense(
        t,
        tagNames: {TransactionFlagTags.excludeFromIo},
      ),
      isTrue,
    );
    expect(TransactionAccountingFlags.excludesFromIncomeExpense(t), isFalse);
  });

  test('转账始终不计入收支且不可切换', () {
    final now = DateTime(2026, 6, 10);
    final t = Transaction(
      uuid: 'u2',
      bookId: 1,
      type: TransactionType.transfer,
      amount: 500,
      categoryId: 1,
      date: now,
      createdAt: now,
      updatedAt: now,
    );
    expect(TransactionAccountingFlags.excludesFromIncomeExpense(t), isTrue);
    expect(TransactionAccountingFlags.isImportMetadataIoExcluded(t), isTrue);
  });

  test('标签「不计入预算」排除预算统计', () {
    final t = _expense();
    expect(
      TransactionAccountingFlags.excludesFromBudget(
        t,
        budgetCategoryIds: {5, 6},
        tagNames: {TransactionFlagTags.excludeFromBudget},
      ),
      isTrue,
    );
    expect(
      TransactionAccountingFlags.excludesFromBudget(
        t,
        budgetCategoryIds: {5, 6},
      ),
      isFalse,
    );
  });

  test('未设分类预算时支出可切换预算标记', () {
    final t = _expense();
    expect(
      TransactionAccountingFlags.canToggleBudgetFlag(
        t,
        budgetCategoryIds: {},
      ),
      isTrue,
    );
  });

  test('分类不在预算范围时不可切换预算标记', () {
    final t = _expense();
    expect(
      TransactionAccountingFlags.canToggleBudgetFlag(
        t,
        budgetCategoryIds: {6, 7},
      ),
      isFalse,
    );
    expect(
      TransactionAccountingFlags.excludesFromBudget(
        t,
        budgetCategoryIds: {6, 7},
      ),
      isTrue,
    );
  });
}
