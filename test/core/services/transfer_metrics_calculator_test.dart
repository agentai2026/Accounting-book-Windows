import 'package:flutter_test/flutter_test.dart';
import 'package:ezbookkeeping_desktop/core/constants/bookkeeping_metrics_rules.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/services/transfer_metrics_calculator.dart';

void main() {
  test('按净转账规则统计', () {
    final metrics = TransferMetricsCalculator.calculate(
      rows: const [
        StatisticsBriefRow(
          type: TransactionType.expense,
          amount: 168800,
          comment: '@src:cat=转账红包;dir=支出;st=交易成功@',
        ),
        StatisticsBriefRow(
          type: TransactionType.transfer,
          amount: 2003279,
          comment: '@src:cat=投资理财;dir=不计收支;st=交易成功@',
        ),
      ],
      mode: TransferMetricMode.netTransfer,
    );

    expect(metrics.count, 1);
    expect(metrics.amountCents, 168800);
  });
}
