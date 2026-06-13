import 'package:flutter_test/flutter_test.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/services/income_expense_totals_calculator.dart';
import 'package:ezbookkeeping_desktop/core/services/transfer_metrics_calculator.dart';
import 'package:ezbookkeeping_desktop/core/utils/import_source_metadata.dart';

void main() {
  test('净转账支出不计入收支合计', () {
    final comment = ImportSourceMetadata.mergeComment(
      existingComment: null,
      metadata: ImportSourceMetadata.encode(
        categoryName: '转账红包',
        direction: '支出',
        status: '支付成功',
      ),
    );
    final rows = [
      StatisticsBriefRow(
        type: TransactionType.expense,
        amount: 10000,
        comment: comment,
      ),
      StatisticsBriefRow(
        type: TransactionType.expense,
        amount: 5000,
        comment: ImportSourceMetadata.mergeComment(
          existingComment: null,
          metadata: ImportSourceMetadata.encode(
            categoryName: '商业服务',
            direction: '支出',
            status: '支付成功',
          ),
        ),
      ),
    ];

    final totals = IncomeExpenseTotalsCalculator.calculate(rows);
    expect(totals.expenseCents, 5000);
    expect(totals.incomeCents, 0);

    final importTotals = IncomeExpenseTotalsCalculator.toImportTotals(rows);
    expect(importTotals.expenseCount, 1);
    expect(importTotals.expenseCents, 5000);
    expect(importTotals.transferCount, 1);
    expect(importTotals.transferCents, 10000);
  });
}
