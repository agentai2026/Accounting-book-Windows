import 'package:ezbookkeeping_desktop/core/constants/bookkeeping_metrics_rules.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/services/alipay_csv_summary_parser.dart';
import 'package:ezbookkeeping_desktop/core/services/transfer_metrics_calculator.dart';
import 'package:ezbookkeeping_desktop/core/utils/import_source_metadata.dart';

/// 按记账规则从流水元数据汇总总收支（与支付宝标准统计对齐）
class IncomeExpenseTotalsCalculator {
  IncomeExpenseTotalsCalculator._();

  static ({int expenseCents, int incomeCents}) calculate(
    List<StatisticsBriefRow> rows,
  ) {
    final hasMetadata =
        rows.any((row) => row.comment?.contains('@src:') == true);

    if (!hasMetadata) {
      return _sumByTransactionType(rows);
    }

    var expenseCents = 0;
    var incomeCents = 0;
    for (final row in rows) {
      final meta = ImportSourceMetadata.parse(row.comment);
      final category = meta?.categoryName;
      final direction =
          meta?.direction ?? TransferMetricsCalculator.directionFromType(row.type);
      final status = meta?.status ?? '交易成功';

      if (BookkeepingMetricsRules.countsInExpenseTotal(
        categoryName: category,
        direction: direction,
        status: status,
      )) {
        expenseCents += row.amount;
      }
      if (BookkeepingMetricsRules.countsInIncomeTotal(
        categoryName: category,
        direction: direction,
        status: status,
      )) {
        incomeCents += row.amount;
      }
    }

    return (expenseCents: expenseCents, incomeCents: incomeCents);
  }

  static ({int expenseCents, int incomeCents}) _sumByTransactionType(
    List<StatisticsBriefRow> rows,
  ) {
    var expenseCents = 0;
    var incomeCents = 0;
    for (final row in rows) {
      switch (row.type) {
        case TransactionType.expense:
          expenseCents += row.amount;
        case TransactionType.income:
          incomeCents += row.amount;
        case TransactionType.transfer:
          break;
      }
    }
    return (expenseCents: expenseCents, incomeCents: incomeCents);
  }

  /// 与统计页一致的导入汇总（收支金额 + 笔数）
  static TransactionImportTotals toImportTotals(
    List<StatisticsBriefRow> rows,
  ) {
    final amounts = calculate(rows);
    final hasMetadata =
        rows.any((row) => row.comment?.contains('@src:') == true);

    var expenseCount = 0;
    var incomeCount = 0;
    var transferCount = 0;
    var transferCents = 0;

    for (final row in rows) {
      if (hasMetadata) {
        final meta = ImportSourceMetadata.parse(row.comment);
        final category = meta?.categoryName;
        final direction =
            meta?.direction ?? TransferMetricsCalculator.directionFromType(row.type);
        final status = meta?.status ?? '交易成功';

        if (BookkeepingMetricsRules.countsInExpenseTotal(
          categoryName: category,
          direction: direction,
          status: status,
        )) {
          expenseCount++;
        } else if (BookkeepingMetricsRules.countsInIncomeTotal(
          categoryName: category,
          direction: direction,
          status: status,
        )) {
          incomeCount++;
        } else {
          transferCount++;
          transferCents += row.amount;
        }
      } else {
        switch (row.type) {
          case TransactionType.expense:
            expenseCount++;
          case TransactionType.income:
            incomeCount++;
          case TransactionType.transfer:
            transferCount++;
            transferCents += row.amount;
        }
      }
    }

    return TransactionImportTotals(
      expenseCount: expenseCount,
      incomeCount: incomeCount,
      transferCount: transferCount,
      expenseCents: amounts.expenseCents,
      incomeCents: amounts.incomeCents,
      transferCents: transferCents,
    );
  }
}
