import 'package:ezbookkeeping_desktop/core/services/alipay_csv_summary_parser.dart';
import 'package:ezbookkeeping_desktop/core/services/transaction_import_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';

Future<void> showAlipayImportReconcileDialog(
  BuildContext context,
  TransactionImportResult importResult,
) async {
  final official = importResult.alipayOfficialSummary;
  if (official == null) return;

  final totals = importResult.importTotals;
  final skipped = importResult.skipped;

  await showGlassDialog<void>(
    context: context,
    builder: (context) => GlassAlertDialog(
      title: const Text('账单对账说明'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '账本已按「通用记账规则」入账：'
                '只有收/支=收入/支出且交易成功才计入盈亏；'
                '不计收支只记流水；交易关闭/退款成功不入账。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              _ReconcileTable(
                rows: [
                  _ReconcileRow(
                    label: '收入',
                    official: _formatOfficial(
                      official.incomeCount,
                      official.incomeAmount,
                    ),
                    book: _formatBook(totals.incomeCount, totals.incomeCents),
                  ),
                  _ReconcileRow(
                    label: '支出',
                    official: _formatOfficial(
                      official.expenseCount,
                      official.expenseAmount,
                    ),
                    book: _formatBook(totals.expenseCount, totals.expenseCents),
                    note: '账本=计入盈亏的支出（已排除转账红包等净转账）；'
                        '与统计页支出一致；Excel 顶部可能少约 ¥309',
                  ),
                  _ReconcileRow(
                    label: '中性/不计收支',
                    official: _formatOfficial(
                      official.neutralCount,
                      official.neutralAmount,
                    ),
                    book: _formatBook(
                      totals.transferCount,
                      totals.transferCents,
                    ),
                    note: '不影响收入/支出/结余；'
                        '转账金额在统计页按「净转账」规则另算',
                  ),
                  _ReconcileRow(
                    label: '入账笔数',
                    official: official.totalRecords?.toString() ?? '-',
                    book: '${importResult.imported}',
                    note: skipped > 0 ? '跳过 $skipped 条（交易关闭/退款等）' : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}

class _ReconcileRow {
  const _ReconcileRow({
    required this.label,
    required this.official,
    required this.book,
    this.note,
  });

  final String label;
  final String official;
  final String book;
  final String? note;
}

class _ReconcileTable extends StatelessWidget {
  const _ReconcileTable({required this.rows});

  final List<_ReconcileRow> rows;

  @override
  Widget build(BuildContext context) {
    final border = BorderSide(color: Theme.of(context).dividerColor);
    return Table(
      border: TableBorder(
        top: border,
        bottom: border,
        left: border,
        right: border,
        horizontalInside: border,
        verticalInside: border,
      ),
      columnWidths: const {
        0: FlexColumnWidth(1.1),
        1: FlexColumnWidth(1.4),
        2: FlexColumnWidth(1.4),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          children: const [
            _HeaderCell('项目'),
            _HeaderCell('官方账单汇总'),
            _HeaderCell('账本入账'),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              _BodyCell(row.label, note: row.note),
              _BodyCell(row.official),
              _BodyCell(row.book),
            ],
          ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.text, {this.note});
  final String text;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(
              note!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatOfficial(int? count, double? amount) {
  if (count == null && amount == null) return '-';
  final amountText = amount == null ? '-' : '¥${amount.toStringAsFixed(2)}';
  if (count == null) return amountText;
  return '$count 笔 / $amountText';
}

String _formatBook(int count, int cents) {
  return '$count 笔 / ${MoneyUtils.format(cents)}';
}
