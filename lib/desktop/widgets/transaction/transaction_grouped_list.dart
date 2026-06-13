import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/transaction.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/settings_models.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_styles.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/transaction_row_sort.dart';

/// 参考 UI：收入偏红、支出偏青
class TransactionListColors {
  TransactionListColors._();

  static const incomeText = Color(0xFFC04848);
  static const expenseText = Color(0xFF1B8C7E);
}

class TransactionGroupedList extends ConsumerWidget {
  const TransactionGroupedList({
    super.key,
    required this.rows,
    required this.currencyCode,
    this.onTap,
    this.onDelete,
    this.groupByDate = true,
    this.showHeader = true,
  });

  final List<TransactionRowData> rows;
  final String currencyCode;
  final void Function(TransactionRowData row)? onTap;
  final void Function(TransactionRowData row)? onDelete;
  final bool groupByDate;
  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final settings = ref.watch(settingsProvider);
    final incomeColor = ref.watch(incomeColorProvider);
    final expenseColor = ref.watch(expenseColorProvider);

    if (!groupByDate) {
      final sorted = sortTransactionRows(
        rows,
        timeDescending: settings.billTimeDesc,
      );
      return ListView(
        children: [
          if (showHeader) const _TableHeader(),
          ...sorted.map((row) => _TransactionRow(
                row: row,
                currencyCode: currencyCode,
                incomeColor: incomeColor,
                expenseColor: expenseColor,
                billInfoMode: settings.billInfoMode,
                onTap: onTap == null ? null : () => onTap!(row),
                onDelete: onDelete == null ? null : () => onDelete!(row),
              )),
        ],
      );
    }

    final groups = <DateTime, List<TransactionRowData>>{};
    for (final row in rows) {
      final day = AppDateUtils.startOfDay(row.transaction.date);
      groups.putIfAbsent(day, () => []).add(row);
    }

    final sortedDays = groups.keys.toList()
      ..sort((a, b) => settings.billDateDesc ? b.compareTo(a) : a.compareTo(b));

    return CustomScrollView(
      slivers: [
        if (showHeader) const SliverToBoxAdapter(child: _TableHeader()),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final day = sortedDays[index];
              final dayRows = sortTransactionRows(
                groups[day]!,
                timeDescending: settings.billTimeDesc,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DayGroupHeader(
                    day: day,
                    rows: dayRows,
                    currencyCode: currencyCode,
                    incomeColor: incomeColor,
                    expenseColor: expenseColor,
                  ),
                  ...dayRows.map(
                    (row) => _TransactionRow(
                      row: row,
                      currencyCode: currencyCode,
                      incomeColor: incomeColor,
                      expenseColor: expenseColor,
                      billInfoMode: settings.billInfoMode,
                      onTap: onTap == null ? null : () => onTap!(row),
                      onDelete:
                          onDelete == null ? null : () => onDelete!(row),
                    ),
                  ),
                ],
              );
            },
            childCount: sortedDays.length,
          ),
        ),
      ],
    );
  }
}

class _DayGroupHeader extends StatelessWidget {
  const _DayGroupHeader({
    required this.day,
    required this.rows,
    required this.currencyCode,
    required this.incomeColor,
    required this.expenseColor,
  });

  final DateTime day;
  final List<TransactionRowData> rows;
  final String currencyCode;
  final Color incomeColor;
  final Color expenseColor;

  @override
  Widget build(BuildContext context) {
    var income = 0;
    var expense = 0;
    for (final row in rows) {
      switch (row.transaction.type) {
        case TransactionType.income:
          income += row.transaction.amount;
        case TransactionType.expense:
          expense += row.transaction.amount;
        case TransactionType.transfer:
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      color: AppThemeColors.panelFill(context).withValues(alpha: 0.55),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppDateUtils.formatDateChineseWithWeekday(day),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppThemeColors.textPrimary(context),
                  ),
            ),
          ),
          if (income > 0)
            Text(
              '+${MoneyUtils.formatSpaced(income, currencyCode: currencyCode)}',
              style: TextStyle(
                color: incomeColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (income > 0 && expense > 0) const SizedBox(width: 12),
          if (expense > 0)
            Text(
              '-${MoneyUtils.formatSpaced(expense, currencyCode: currencyCode)}',
              style: TextStyle(
                color: expenseColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppThemeColors.textSecondary(context),
          fontWeight: FontWeight.w600,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppThemeColors.border(context)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 64, child: _HeaderCell(label: '时间', style: style)),
          Expanded(flex: 2, child: _HeaderCell(label: '分类', style: style)),
          Expanded(flex: 2, child: _HeaderCell(label: '金额', style: style)),
          Expanded(flex: 2, child: _HeaderCell(label: '账户', style: style)),
          Expanded(flex: 2, child: _HeaderCell(label: '标签', style: style)),
          Expanded(flex: 3, child: _HeaderCell(label: '备注', style: style)),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.label, required this.style});

  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: style),
        const SizedBox(width: 2),
        Icon(Icons.unfold_more, size: 14, color: AppThemeColors.textHint(context).withValues(alpha: 0.8)),
      ],
    );
  }
}

class _TransactionRow extends StatefulWidget {
  const _TransactionRow({
    required this.row,
    required this.currencyCode,
    required this.incomeColor,
    required this.expenseColor,
    required this.billInfoMode,
    this.onTap,
    this.onDelete,
  });

  final TransactionRowData row;
  final String currencyCode;
  final Color incomeColor;
  final Color expenseColor;
  final BillInfoDisplayMode billInfoMode;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  State<_TransactionRow> createState() => _TransactionRowState();
}

class _TransactionRowState extends State<_TransactionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final t = row.transaction;
    final timeText = switch (widget.billInfoMode) {
      BillInfoDisplayMode.note => '—',
      BillInfoDisplayMode.time || BillInfoDisplayMode.all =>
        DateFormat('HH:mm').format(t.date),
    };
    final remarkText = switch (widget.billInfoMode) {
      BillInfoDisplayMode.time => '—',
      BillInfoDisplayMode.note || BillInfoDisplayMode.all => _remarkText(t),
    };
    final amountText =
        MoneyUtils.formatSpaced(t.amount, currencyCode: widget.currencyCode);
    final amountColor = switch (t.type) {
      TransactionType.expense => widget.expenseColor,
      TransactionType.income => widget.incomeColor,
      TransactionType.transfer => AppColors.transfer,
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered
            ? AppThemeColors.selectedBackground(context).withValues(alpha: 0.35)
            : Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppThemeColors.border(context),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    timeText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppThemeColors.textPrimary(context),
                        ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      _CategoryBadge(type: t.type, icon: row.categoryIcon),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          row.categoryName,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppThemeColors.textPrimary(context),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    amountText,
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    row.accountName,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppThemeColors.textPrimary(context),
                        ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _TagBadge(text: row.tagText),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    remarkText,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemeColors.textSecondary(context),
                        ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: AnimatedOpacity(
                    opacity: _hovered && widget.onDelete != null ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: IconButton(
                      tooltip: '删除',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.expense,
                      ),
                      onPressed: widget.onDelete,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.type, this.icon});

  final TransactionType type;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final badgeIcon = switch (type) {
      TransactionType.expense => Icons.remove,
      TransactionType.income => Icons.add,
      TransactionType.transfer => Icons.swap_horiz,
    };
    final color = switch (type) {
      TransactionType.expense => TransactionListColors.expenseText,
      TransactionType.income => TransactionListColors.incomeText,
      TransactionType.transfer => AppColors.transfer,
    };

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppThemeColors.border(context)),
        color: GlassStyles.panelTint(context, light: 0.28, dark: 0.22),
      ),
      child: Icon(
        icon ?? badgeIcon,
        size: 16,
        color: color,
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: GlassStyles.panelTint(context, light: 0.28, dark: 0.22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppThemeColors.border(context)),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppThemeColors.textSecondary(context),
              ),
        ),
      ),
    );
  }
}

String _remarkText(Transaction t) {
  final remark = t.comment?.trim();
  final payer = t.payer?.trim();
  final parts = <String>[
    if (remark != null && remark.isNotEmpty) remark,
    if (payer != null && payer.isNotEmpty) payer,
  ];
  if (parts.isNotEmpty) return parts.join(' · ');
  final legacy = t.description?.trim();
  if (legacy != null && legacy.isNotEmpty) return legacy;
  return '—';
}
