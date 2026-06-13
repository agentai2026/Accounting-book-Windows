import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

class TransactionDataTable extends StatelessWidget {
  const TransactionDataTable({
    super.key,
    required this.rows,
    required this.onDelete,
  });

  final List<TransactionRowData> rows;
  final void Function(TransactionRowData row) onDelete;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.panelBackground),
        headingTextStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
        columns: const [
          DataColumn(label: Text('时间')),
          DataColumn(label: Text('类型')),
          DataColumn(label: Text('分类')),
          DataColumn(label: Text('账户')),
          DataColumn(label: Text('备注')),
          DataColumn(label: Text('金额'), numeric: true),
          DataColumn(label: Text('操作')),
        ],
        rows: rows.map((row) {
          final t = row.transaction;
          final typeColor = switch (t.type) {
            TransactionType.expense => AppColors.expense,
            TransactionType.income => AppColors.income,
            TransactionType.transfer => AppColors.transfer,
          };

          return DataRow(
            cells: [
              DataCell(Text(_formatDate(t.date))),
              DataCell(Text(_typeLabel(t.type))),
              DataCell(Text(row.categoryName)),
              DataCell(Text(row.accountName)),
              DataCell(Text(t.comment ?? t.description ?? '-')),
              DataCell(
                Text(
                  row.amountText,
                  style: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                IconButton(
                  tooltip: '删除',
                  icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                  onPressed: () => onDelete(row),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _typeLabel(TransactionType type) {
    return switch (type) {
      TransactionType.expense => '支出',
      TransactionType.income => '收入',
      TransactionType.transfer => '转账',
    };
  }
}
