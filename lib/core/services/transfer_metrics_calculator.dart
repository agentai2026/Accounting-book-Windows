import 'package:ezbookkeeping_desktop/core/constants/bookkeeping_metrics_rules.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/import_source_metadata.dart';

class TransferMetrics {
  const TransferMetrics({
    required this.count,
    required this.amountCents,
  });

  final int count;
  final int amountCents;
}

class StatisticsBriefRow {
  const StatisticsBriefRow({
    required this.type,
    required this.amount,
    this.comment,
  });

  final TransactionType type;
  final int amount;
  final String? comment;
}

class TransferMetricsCalculator {
  TransferMetricsCalculator._();

  static TransferMetrics calculate({
    required List<StatisticsBriefRow> rows,
    required TransferMetricMode mode,
  }) {
    var count = 0;
    var amountCents = 0;

    for (final row in rows) {
      final meta = ImportSourceMetadata.parse(row.comment);
      final category = meta?.categoryName;
      final direction = meta?.direction ?? _directionFromType(row.type);
      final status = meta?.status ?? '交易成功';

      final matched = switch (mode) {
        TransferMetricMode.netTransfer =>
          BookkeepingMetricsRules.countsAsNetTransfer(
            categoryName: category,
            direction: direction,
            status: status,
          ),
        TransferMetricMode.totalFlow =>
          BookkeepingMetricsRules.countsAsTransferTotalFlow(
            categoryName: category,
            direction: direction,
            status: status,
          ),
      };

      if (!matched) continue;
      count++;
      if (mode == TransferMetricMode.netTransfer) {
        if (BookkeepingMetricsRules.countsAsExpense(
          direction: direction,
          status: status,
        )) {
          amountCents += row.amount;
        } else if (BookkeepingMetricsRules.countsAsIncome(
          direction: direction,
          status: status,
        )) {
          amountCents -= row.amount;
        }
      } else {
        amountCents += row.amount;
      }
    }

    // 无元数据时回退：按转账类型合计（兼容旧导入）
    if (count == 0 && rows.any((r) => r.comment?.contains('@src:') != true)) {
      for (final row in rows) {
        if (row.type != TransactionType.transfer) continue;
        count++;
        amountCents += row.amount;
      }
    }

    return TransferMetrics(count: count, amountCents: amountCents);
  }

  static String? directionFromType(TransactionType type) {
    return switch (type) {
      TransactionType.expense => '支出',
      TransactionType.income => '收入',
      TransactionType.transfer => '不计收支',
    };
  }

  static String? _directionFromType(TransactionType type) =>
      directionFromType(type);
}
