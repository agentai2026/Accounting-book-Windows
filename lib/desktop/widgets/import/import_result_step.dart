import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/services/transaction_import_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/import/import_wizard_shared.dart';

/// 导入完成页
class ImportResultStep extends StatelessWidget {
  const ImportResultStep({
    super.key,
    required this.result,
    this.fileName,
  });

  final TransactionImportResult result;
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    final totals = result.importTotals;
    final skipped = result.skipped;

    return Column(
      key: const ValueKey('finalResult'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ImportStepHeader(
          title: '导入完成',
          description: '收支金额与统计页口径一致；转账红包等净转账计入「不计收支」。',
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.income.withValues(alpha: 0.18),
                          AppColors.primary.withValues(alpha: 0.08),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 44,
                      color: AppColors.income,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${result.imported} 条',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -1,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '成功导入',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  if (fileName != null) ...[
                    const SizedBox(height: 8),
                    ImportHintText('来源：$fileName'),
                  ],
                  const SizedBox(height: 32),
                  _MetricsRow(
                    items: [
                      _MetricItem(
                        label: '支出',
                        count: totals.expenseCount,
                        amount: totals.expenseCents,
                        color: AppColors.expense,
                      ),
                      _MetricItem(
                        label: '收入',
                        count: totals.incomeCount,
                        amount: totals.incomeCents,
                        color: AppColors.income,
                      ),
                      if (totals.transferCount > 0)
                        _MetricItem(
                          label: '不计收支',
                          count: totals.transferCount,
                          amount: totals.transferCents,
                          color: AppColors.transfer,
                        ),
                      if (skipped > 0)
                        _MetricItem(
                          label: '未导入',
                          count: skipped,
                          amount: null,
                          color: AppColors.textSecondary,
                        ),
                    ],
                  ),
                  if (result.skipReasons.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SkipPanel(
                      reasons: result.skipReasons,
                      total: skipped,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricItem {
  const _MetricItem({
    required this.label,
    required this.count,
    required this.color,
    this.amount,
  });

  final String label;
  final int count;
  final int? amount;
  final Color color;
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.items});

  final List<_MetricItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Container(
              width: 1,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: AppColors.divider,
            ),
          _MetricCell(item: items[i]),
        ],
      ],
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${item.count}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: item.color,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        if (item.amount != null) ...[
          const SizedBox(height: 2),
          Text(
            MoneyUtils.format(item.amount!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
        ],
      ],
    );
  }
}

class _SkipPanel extends StatelessWidget {
  const _SkipPanel({required this.reasons, required this.total});

  final Map<String, int> reasons;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ImportWizardShared.surfaceDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '另有 $total 条未导入',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          for (final e in reasons.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${e.key}  ${e.value} 条',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
