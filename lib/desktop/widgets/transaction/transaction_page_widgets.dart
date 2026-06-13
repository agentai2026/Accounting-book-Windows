import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/services/statistics_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_styles.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_calendar_picker.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/search_bar.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/transaction_add_menu_button.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/transaction_grouped_list.dart';

String transactionViewTitle(TransactionDetailView view) {
  return switch (view) {
    TransactionDetailView.list => '交易列表',
    TransactionDetailView.calendar => '交易日历',
    TransactionDetailView.album => '交易相册',
  };
}

IconData transactionViewIcon(TransactionDetailView view) {
  return switch (view) {
    TransactionDetailView.list => Icons.receipt_long_outlined,
    TransactionDetailView.calendar => Icons.calendar_month_outlined,
    TransactionDetailView.album => Icons.photo_library_outlined,
  };
}

class TransactionPageHeader extends StatelessWidget {
  const TransactionPageHeader({
    super.key,
    required this.view,
    required this.searchController,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.onAdd,
    required this.onAiRecognize,
    required this.onImport,
  });

  final TransactionDetailView view;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;
  final VoidCallback onAiRecognize;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            transactionViewIcon(view),
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          transactionViewTitle(view),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppThemeColors.textPrimary(context),
              ),
        ),
        const SizedBox(width: 16),
        TransactionAddMenuButton(
          onAdd: onAdd,
          onAiRecognize: onAiRecognize,
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onImport,
          icon: const Icon(Icons.upload_file_outlined, size: 18),
          label: const Text('导入'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        IconButton(
          tooltip: '刷新',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, size: 20),
          color: AppThemeColors.textSecondary(context),
        ),
        const Spacer(),
        SizedBox(
          width: 280,
          child: AppSearchBar(
            controller: searchController,
            hintText: '搜索备注/付款人',
            onChanged: onSearchChanged,
          ),
        ),
      ],
    );
  }
}

class TransactionSummaryCards extends StatelessWidget {
  const TransactionSummaryCards({
    super.key,
    required this.summary,
    required this.transactionCount,
    required this.currencyCode,
  });

  final PeriodSummary summary;
  final int transactionCount;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final net = summary.netCents;
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: '收入',
            value: MoneyUtils.formatSpaced(
              summary.incomeCents,
              currencyCode: currencyCode,
            ),
            color: TransactionListColors.incomeText,
            icon: Icons.south_west,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: '支出',
            value: MoneyUtils.formatSpaced(
              summary.expenseCents,
              currencyCode: currencyCode,
            ),
            color: TransactionListColors.expenseText,
            icon: Icons.north_east,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: '结余',
            value: MoneyUtils.formatSpaced(net, currencyCode: currencyCode),
            color: net >= 0
                ? TransactionListColors.incomeText
                : TransactionListColors.expenseText,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: '交易笔数',
            value: '$transactionCount',
            color: AppColors.primary,
            icon: Icons.format_list_numbered,
            isCount: true,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.isCount = false,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isCount;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppThemeColors.textHint(context),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCount ? AppThemeColors.textPrimary(context) : color,
                      ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class TransactionRangeNavigator extends ConsumerWidget {
  const TransactionRangeNavigator({super.key, required this.filter});

  final TransactionFilterState filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rangeText = filter.showAllPeriod
        ? '全部时间'
        : filter.usesCustomRange
            ? '${AppDateUtils.formatDate(filter.rangeStart)} — ${AppDateUtils.formatDate(filter.rangeEnd)}'
            : DateFormat('yyyy年M月', 'zh_CN').format(filter.selectedMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppThemeColors.panelFill(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppThemeColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range_outlined, size: 18, color: AppThemeColors.textHint(context)),
          const SizedBox(width: 8),
          Text(
            '时间范围',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppThemeColors.textSecondary(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 8),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: '上一月',
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: filter.usesCustomRange || filter.showAllPeriod
                ? null
                : () => ref.read(transactionFilterProvider.notifier).prevMonth(),
          ),
          Expanded(
            child: Text(
              rangeText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: '下一月',
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: filter.usesCustomRange || filter.showAllPeriod
                ? null
                : () => ref.read(transactionFilterProvider.notifier).nextMonth(),
          ),
          TextButton(
            onPressed: () =>
                ref.read(transactionFilterProvider.notifier).setShowAllPeriod(),
            child: Text(
              '全部',
              style: TextStyle(
                color: filter.showAllPeriod
                    ? AppColors.primary
                    : AppThemeColors.textSecondary(context),
                fontWeight:
                    filter.showAllPeriod ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionFilterSidebar extends ConsumerWidget {
  const TransactionFilterSidebar({super.key, required this.filter});

  final TransactionFilterState filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final months = _recentMonths(14);
    final isAlbum = filter.view == TransactionDetailView.album;

    return SizedBox(
      width: 220,
      child: GlassSurface(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '视图',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppThemeColors.textHint(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          for (final view in TransactionDetailView.values) ...[
            _ViewTab(
              label: transactionViewTitle(view),
              icon: transactionViewIcon(view),
              selected: filter.view == view,
              onTap: () =>
                  ref.read(transactionFilterProvider.notifier).setView(view),
            ),
            if (view != TransactionDetailView.values.last)
              const SizedBox(height: 4),
          ],
          const SizedBox(height: 20),
          Text(
            '交易类型',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppThemeColors.textHint(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _TypeChip(
                label: '全部',
                selected: filter.type == null,
                onTap: () =>
                    ref.read(transactionFilterProvider.notifier).setType(null),
              ),
              for (final type in TransactionType.values)
                _TypeChip(
                  label: transactionTypeLabel(type),
                  selected: filter.type == type,
                  color: _typeColor(type),
                  onTap: () => ref
                      .read(transactionFilterProvider.notifier)
                      .setType(type),
                ),
            ],
          ),
          if (filter.view == TransactionDetailView.list) ...[
            const SizedBox(height: 20),
            Text(
              '每页条数',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppThemeColors.textHint(context),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final size in const [15, 30, 50]) ...[
                  if (size != 15) const SizedBox(width: 6),
                  Expanded(
                    child: _PageSizeChip(
                      label: '$size',
                      selected: filter.pageSize == size,
                      onTap: () => ref
                          .read(transactionFilterProvider.notifier)
                          .setPageSize(size),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 20),
          Text(
            '月份',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppThemeColors.textHint(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                if (isAlbum)
                  _MonthTile(
                    label: '全部',
                    selected: filter.showAllPeriod,
                    onTap: () => ref
                        .read(transactionFilterProvider.notifier)
                        .setShowAllPeriod(),
                  ),
                for (final month in months)
                  _MonthTile(
                    label: DateFormat('yyyy年M月', 'zh_CN').format(month),
                    selected: !filter.showAllPeriod &&
                        !filter.usesCustomRange &&
                        filter.selectedMonth.year == month.year &&
                        filter.selectedMonth.month == month.month,
                    onTap: () => ref
                        .read(transactionFilterProvider.notifier)
                        .setMonth(month),
                  ),
                _MonthTile(
                  label: '自定义日期',
                  selected: filter.usesCustomRange,
                  onTap: () => _pickCustomRange(context, ref),
                ),
              ],
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  List<DateTime> _recentMonths(int count) {
    final now = DateTime.now();
    return List.generate(count, (i) => DateTime(now.year, now.month - i));
  }

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final range = await showAppDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialRange: DateTimeRange(
        start: ref.read(transactionFilterProvider).rangeStart,
        end: ref.read(transactionFilterProvider).rangeEnd,
      ),
    );

    if (range == null) return;
    ref.read(transactionFilterProvider.notifier).setCustomRange(
          range.start,
          range.end,
        );
  }

  Color _typeColor(TransactionType type) {
    return switch (type) {
      TransactionType.expense => TransactionListColors.expenseText,
      TransactionType.income => TransactionListColors.incomeText,
      TransactionType.transfer => AppColors.transfer,
    };
  }
}

class TransactionActiveFiltersBar extends ConsumerWidget {
  const TransactionActiveFiltersBar({super.key, required this.filter});

  final TransactionFilterState filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chips = <Widget>[];

    if (filter.keyword.trim().isNotEmpty) {
      chips.add(_FilterChip(
        label: '搜索: ${filter.keyword.trim()}',
        onRemove: () {
          ref.read(transactionFilterProvider.notifier).setKeyword('');
        },
      ));
    }
    if (filter.type != null) {
      chips.add(_FilterChip(
        label: transactionTypeLabel(filter.type!),
        onRemove: () =>
            ref.read(transactionFilterProvider.notifier).setType(null),
      ));
    }
    if (filter.showAllPeriod) {
      chips.add(const _FilterChip(label: '全部时间', removable: false));
    } else if (filter.usesCustomRange) {
      chips.add(_FilterChip(
        label:
            '${AppDateUtils.formatDate(filter.rangeStart)} — ${AppDateUtils.formatDate(filter.rangeEnd)}',
        onRemove: () =>
            ref.read(transactionFilterProvider.notifier).clearCustomRange(),
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '已筛选',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppThemeColors.textHint(context),
                ),
          ),
          ...chips,
          TextButton(
            onPressed: () => ref.read(transactionFilterProvider.notifier).reset(),
            child: const Text('清除全部'),
          ),
        ],
      ),
    );
  }
}

class TransactionPaginationBar extends ConsumerWidget {
  const TransactionPaginationBar({
    super.key,
    required this.filter,
    required this.countAsync,
  });

  final TransactionFilterState filter;
  final AsyncValue<int> countAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (filter.view != TransactionDetailView.list) {
      return const SizedBox.shrink();
    }

    final total = countAsync.maybeWhen(data: (c) => c, orElse: () => 0);
    if (total == 0) return const SizedBox.shrink();

    final totalPages = (total / filter.pageSize).ceil().clamp(1, 9999);
    final currentPage = filter.page + 1;
    final start = filter.page * filter.pageSize + 1;
    final end = ((filter.page + 1) * filter.pageSize).clamp(0, total);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '第 $start–$end 条，共 $total 条',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppThemeColors.textSecondary(context),
                ),
          ),
          const SizedBox(width: 16),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: '上一页',
            onPressed: filter.page > 0
                ? () => ref
                    .read(transactionFilterProvider.notifier)
                    .setPage(filter.page - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppThemeColors.selectedBackground(context),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppThemeColors.border(context)),
            ),
            child: Text(
              '$currentPage / $totalPages',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: '下一页',
            onPressed: currentPage < totalPages
                ? () => ref
                    .read(transactionFilterProvider.notifier)
                    .setPage(filter.page + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class TransactionListEmptyPanel extends StatelessWidget {
  const TransactionListEmptyPanel({
    super.key,
    required this.onAdd,
    required this.onImport,
  });

  final VoidCallback onAdd;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppThemeColors.textHint(context).withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无交易记录',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppThemeColors.textSecondary(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加账单、导入数据，或调整筛选条件试试',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppThemeColors.textHint(context),
                ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onImport,
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: const Text('导入'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ViewTab extends StatelessWidget {
  const _ViewTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppThemeColors.selectedBackground(context) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.primary : AppThemeColors.textSecondary(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                        color:
                            selected ? AppColors.primary : AppThemeColors.textPrimary(context),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageSizeChip extends StatelessWidget {
  const _PageSizeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppThemeColors.panelFill(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppThemeColors.border(context),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? AppColors.primary : AppThemeColors.textSecondary(context),
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 12,
        color: selected ? activeColor : AppThemeColors.textSecondary(context),
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      selectedColor: activeColor.withValues(alpha: 0.12),
      backgroundColor: AppThemeColors.panelFill(context),
      side: BorderSide(
        color: selected ? activeColor.withValues(alpha: 0.4) : AppThemeColors.border(context),
      ),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _MonthTile extends StatelessWidget {
  const _MonthTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
        decoration: BoxDecoration(
          color: selected
              ? AppThemeColors.selectedBackground(context).withValues(alpha: 0.5)
              : null,
          borderRadius: BorderRadius.circular(6),
          border: selected
              ? const Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                )
              : null,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? AppColors.primary : AppThemeColors.textSecondary(context),
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.onRemove,
    this.removable = true,
  });

  final String label;
  final VoidCallback? onRemove;
  final bool removable;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      onDeleted: removable ? onRemove : null,
      deleteIcon: removable ? const Icon(Icons.close, size: 16) : null,
      visualDensity: VisualDensity.compact,
      backgroundColor: AppThemeColors.panelFill(context),
      side: BorderSide(color: AppThemeColors.border(context)),
    );
  }
}
