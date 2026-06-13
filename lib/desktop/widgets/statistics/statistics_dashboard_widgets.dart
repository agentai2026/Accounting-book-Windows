import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/book.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/services/statistics_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/label_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/statistics_strings.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/statistics_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/statistics_page_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/statistics_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_styles.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/home/home_dashboard_widgets.dart';

/// 顶部筛选区
class StatisticsFilterToolbar extends StatelessWidget {
  const StatisticsFilterToolbar({
    super.key,
    required this.filter,
    required this.accounts,
    required this.books,
    required this.rangeLabel,
    required this.onPeriodChanged,
    required this.onCustomRange,
    required this.onTypeChanged,
    required this.onAccountChanged,
    required this.onBookChanged,
    required this.onKeywordChanged,
    required this.onRefresh,
  });

  final StatisticsFilter filter;
  final List<Account> accounts;
  final List<Book> books;
  final String rangeLabel;
  final ValueChanged<StatisticsPeriod> onPeriodChanged;
  final VoidCallback onCustomRange;
  final ValueChanged<TransactionType?> onTypeChanged;
  final ValueChanged<int?> onAccountChanged;
  final ValueChanged<int?> onBookChanged;
  final ValueChanged<String> onKeywordChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        StatisticsStrings.title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.date_range_outlined,
                              size: 14,
                              color: AppColors.primary.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              rangeLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: StatisticsStrings.refresh,
                  onPressed: onRefresh,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.12),
                    foregroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final period in StatisticsPeriod.values)
                  if (period != StatisticsPeriod.custom)
                    StatisticsGlassChip(
                      label: StatisticsFilter.periodLabelFor(period),
                      selected: filter.period == period,
                      onTap: () => onPeriodChanged(period),
                    ),
                StatisticsGlassChip(
                  label: filter.period == StatisticsPeriod.custom
                      ? StatisticsStrings.customRange
                      : StatisticsStrings.custom,
                  selected: filter.period == StatisticsPeriod.custom,
                  onTap: onCustomRange,
                  icon: Icons.calendar_month_outlined,
                ),
                _FilterMenu<TransactionType?>(
                  label: StatisticsStrings.type,
                  value: filter.transactionType,
                  items: const [null, ...TransactionType.values],
                  itemLabel: (v) => v == null
                      ? StatisticsStrings.allTypes
                      : transactionTypeLabel(v),
                  onChanged: onTypeChanged,
                ),
                _FilterMenu<int?>(
                  label: StatisticsStrings.account,
                  value: filter.accountId,
                  items: [
                    null,
                    ...accounts.where((a) => a.id != null).map((a) => a.id!),
                  ],
                  itemLabel: (id) {
                    if (id == null) return StatisticsStrings.allAccounts;
                    return accounts.firstWhere((a) => a.id == id).name;
                  },
                  onChanged: onAccountChanged,
                ),
                _FilterMenu<int?>(
                  label: StatisticsStrings.book,
                  value: filter.bookId,
                  items: [
                    null,
                    ...books.where((b) => b.id != null).map((b) => b.id!),
                  ],
                  itemLabel: (id) {
                    if (id == null) return StatisticsStrings.allBooks;
                    return books.firstWhere((b) => b.id == id).name;
                  },
                  onChanged: onBookChanged,
                ),
                SizedBox(
                  width: 200,
                  child: TextField(
                    onChanged: onKeywordChanged,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: StatisticsStrings.searchHint,
                      hintStyle: TextStyle(color: AppThemeColors.textHint(context)),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppThemeColors.textHint(context),
                        size: 20,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: GlassStyles.fieldFill(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: GlassStyles.divider(context),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: GlassStyles.divider(context),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 标签 + 图表选项合一
class StatisticsControlStrip extends ConsumerWidget {
  const StatisticsControlStrip({
    super.key,
    required this.pageState,
    required this.supportsDailyTrend,
  });

  final StatisticsPageState pageState;
  final bool supportsDailyTrend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(statisticsPageProvider.notifier);
    final chartTypes = chartTypesForTab(pageState.mainTab);

    return GlassSurface(
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tab in StatisticsMainTab.values) ...[
                    if (tab != StatisticsMainTab.values.first)
                      const SizedBox(width: 6),
                    _TabPill(
                      label: mainTabLabel(tab),
                      selected: pageState.mainTab == tab,
                      onTap: () => notifier.setMainTab(tab),
                    ),
                  ],
                ],
              ),
            ),
            if (_showSecondaryRow) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: GlassStyles.divider(context)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (pageState.mainTab == StatisticsMainTab.category)
                    _SegmentPair(
                      leftLabel: '支出',
                      rightLabel: '收入',
                      leftSelected:
                          pageState.categoryMode == StatisticsCategoryMode.expense,
                      onLeft: () => notifier.setCategoryMode(
                        StatisticsCategoryMode.expense,
                      ),
                      onRight: () => notifier.setCategoryMode(
                        StatisticsCategoryMode.income,
                      ),
                    ),
                  if (pageState.mainTab == StatisticsMainTab.trend ||
                      pageState.mainTab == StatisticsMainTab.overview)
                    StatisticsGlassChip(
                      label: pageState.trendMonthly || !supportsDailyTrend
                          ? '按月'
                          : '按日',
                      selected: pageState.trendMonthly || !supportsDailyTrend,
                      onTap: supportsDailyTrend
                          ? () => notifier.setTrendMonthly(!pageState.trendMonthly)
                          : null,
                      icon: Icons.timeline_outlined,
                    ),
                  if (pageState.mainTab == StatisticsMainTab.account) ...[
                    StatisticsGlassChip(
                      label: '净资产',
                      selected: pageState.assetMetric ==
                          StatisticsAssetMetric.netAssets,
                      onTap: () => notifier.setAssetMetric(
                        StatisticsAssetMetric.netAssets,
                      ),
                    ),
                    StatisticsGlassChip(
                      label: '总资产',
                      selected: pageState.assetMetric ==
                          StatisticsAssetMetric.totalAssets,
                      onTap: () => notifier.setAssetMetric(
                        StatisticsAssetMetric.totalAssets,
                      ),
                    ),
                    StatisticsGlassChip(
                      label: '总负债',
                      selected: pageState.assetMetric ==
                          StatisticsAssetMetric.totalLiabilities,
                      onTap: () => notifier.setAssetMetric(
                        StatisticsAssetMetric.totalLiabilities,
                      ),
                    ),
                  ],
                  if (chartTypes.length <= 3)
                    _ChartTypeSegments(
                      types: chartTypes,
                      selected: chartTypes.contains(pageState.chartType)
                          ? pageState.chartType
                          : chartTypes.first,
                      onChanged: notifier.setChartType,
                    )
                  else
                    _FilterMenu<StatisticsChartType>(
                      label: '图表',
                      value: chartTypes.contains(pageState.chartType)
                          ? pageState.chartType
                          : chartTypes.first,
                      items: chartTypes,
                      itemLabel: chartTypeLabel,
                      onChanged: (v) {
                        if (v != null) notifier.setChartType(v);
                      },
                    ),
                  _FilterMenu<StatisticsSortOrder>(
                    label: '排序',
                    value: pageState.sortOrder,
                    items: StatisticsSortOrder.values,
                    itemLabel: (o) => switch (o) {
                      StatisticsSortOrder.displayOrder => '显示顺序',
                      StatisticsSortOrder.amount => '金额',
                      StatisticsSortOrder.name => '名称',
                    },
                    onChanged: (v) {
                      if (v != null) notifier.setSortOrder(v);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _showSecondaryRow =>
      pageState.mainTab != StatisticsMainTab.budget;
}

class StatisticsKpiGrid extends StatelessWidget {
  const StatisticsKpiGrid({
    super.key,
    required this.report,
    required this.assetSummary,
    required this.currencyCode,
    this.budgetKpi,
  });

  final StatisticsFullReport report;
  final AssetSummary assetSummary;
  final String currencyCode;
  final BudgetKpiSummary? budgetKpi;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCard(
        title: StatisticsStrings.expense,
        value: MoneyUtils.formatWithSign(
          report.summary.expenseCents,
          currencyCode: currencyCode,
          isExpense: true,
        ),
        subtitle: _changeText(report.expenseChangePercent),
        color: AppColors.expense,
        icon: Icons.trending_down_rounded,
        featured: true,
      ),
      _KpiCard(
        title: StatisticsStrings.income,
        value: MoneyUtils.formatWithSign(
          report.summary.incomeCents,
          currencyCode: currencyCode,
          isIncome: true,
        ),
        subtitle: _changeText(report.incomeChangePercent),
        color: AppColors.income,
        icon: Icons.trending_up_rounded,
        featured: true,
      ),
      _KpiCard(
        title: StatisticsStrings.balance,
        value: MoneyUtils.formatWithSign(
          report.summary.netCents.abs(),
          currencyCode: currencyCode,
          isIncome: report.summary.netCents >= 0,
          isExpense: report.summary.netCents < 0,
        ),
        subtitle: report.savingsRate == null
            ? '${StatisticsStrings.savingsRate} --'
            : '${StatisticsStrings.savingsRate} ${report.savingsRate!.toStringAsFixed(1)}%',
        color:
            report.summary.netCents >= 0 ? AppColors.income : AppColors.expense,
        icon: Icons.account_balance_wallet_outlined,
        featured: true,
      ),
      _KpiCard(
        title: StatisticsStrings.netAssets,
        value: MoneyUtils.format(
          assetSummary.netAssetsCents,
          currencyCode: currencyCode,
        ),
        subtitle: '${assetSummary.accountCount} ${StatisticsStrings.accountUnit}',
        color: AppColors.primary,
        icon: Icons.savings_outlined,
        featured: true,
      ),
      _KpiCard(
        title: StatisticsStrings.transactionCount,
        value: '${report.transactionCount}',
        subtitle:
            '${StatisticsStrings.transferCount} ${report.transferCount} ${StatisticsStrings.transferUnit}',
        color: AppThemeColors.textSecondary(context),
        icon: Icons.receipt_long_outlined,
      ),
      _KpiCard(
        title: StatisticsStrings.transferAmount,
        value: MoneyUtils.format(
          report.transferAmountCents,
          currencyCode: currencyCode,
        ),
        subtitle: StatisticsStrings.transferTotal,
        color: AppColors.transfer,
        icon: Icons.swap_horiz_rounded,
      ),
      _KpiCard(
        title: StatisticsStrings.reimbursable,
        value: MoneyUtils.format(
          report.reimbursableCents,
          currencyCode: currencyCode,
        ),
        subtitle: report.reimbursableCount > 0
            ? '${report.reimbursableCount} ${StatisticsStrings.reimbursableUnit}'
            : StatisticsStrings.noReimbursable,
        color: const Color(0xFF7B61FF),
        icon: Icons.receipt_outlined,
      ),
      _KpiCard(
        title: StatisticsStrings.budgetUsage,
        value: budgetKpi == null
            ? '--'
            : '${budgetKpi!.usagePercent.toStringAsFixed(0)}%',
        subtitle: budgetKpi == null
            ? StatisticsStrings.noBudget
            : '${budgetKpi!.label} ${MoneyUtils.format(budgetKpi!.spentCents, currencyCode: currencyCode)} / ${MoneyUtils.format(budgetKpi!.budgetCents, currencyCode: currencyCode)}${budgetKpi!.isOverBudget ? ' · ${StatisticsStrings.budgetOver}' : ''}',
        color: budgetKpi?.isOverBudget == true
            ? AppColors.expense
            : AppColors.primary,
        icon: Icons.donut_large_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 960;
        final crossCount = wide ? 4 : 2;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (crossCount - 1)) / crossCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(
                width: itemWidth,
                child: card,
              ),
          ],
        );
      },
    );
  }

  String _changeText(double? percent) {
    if (percent == null) return StatisticsStrings.noCompareData;
    final sign = percent >= 0 ? '+' : '';
    return '${StatisticsStrings.momChange} $sign${percent.toStringAsFixed(1)}%';
  }
}

class StatisticsRankingTable extends StatelessWidget {
  const StatisticsRankingTable({
    super.key,
    required this.title,
    required this.rows,
    required this.currencyCode,
    this.accentColor = AppColors.expense,
    this.fillHeight = false,
  });

  final String title;
  final List<({String name, int amountCents, double percentage})> rows;
  final String currencyCode;
  final Color accentColor;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return StatisticsSectionCard(
        title: title,
        icon: Icons.leaderboard_outlined,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: Text(
              StatisticsStrings.noData,
              style: TextStyle(color: AppThemeColors.textHint(context)),
            ),
          ),
        ),
      );
    }

    final maxAmount = rows.first.amountCents;
    final list = ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: !fillHeight,
      physics: fillHeight ? null : const NeverScrollableScrollPhysics(),
      itemCount: rows.length < 12 ? rows.length : 12,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        return Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${i + 1}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rows[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        MoneyUtils.format(
                          rows[i].amountCents,
                          currencyCode: currencyCode,
                        ),
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${rows[i].percentage.toStringAsFixed(1)}%',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppThemeColors.textHint(context),
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:
                          maxAmount > 0 ? rows[i].amountCents / maxAmount : 0,
                      minHeight: 6,
                      backgroundColor: accentColor.withValues(alpha: 0.08),
                      color: accentColor.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    return StatisticsSectionCard(
      title: title,
      icon: Icons.leaderboard_outlined,
      accentColor: accentColor,
      expandChild: fillHeight,
      child: fillHeight
          ? list
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: list,
            ),
    );
  }
}

/// 本期统计摘要条（毛玻璃横条）
class StatisticsPeriodInsightBar extends StatelessWidget {
  const StatisticsPeriodInsightBar({
    super.key,
    required this.report,
    required this.currencyCode,
  });

  final StatisticsFullReport report;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final expenseChange = report.expenseChangePercent;
    final changeText = expenseChange == null
        ? StatisticsStrings.noCompareData
        : '${StatisticsStrings.momChange} ${expenseChange >= 0 ? '+' : ''}${expenseChange.toStringAsFixed(1)}%';
    final savingsText = report.savingsRate == null
        ? '--'
        : '${report.savingsRate!.toStringAsFixed(1)}%';

    final items = [
      _InsightItem(
        icon: Icons.calendar_today_outlined,
        label: '统计天数',
        value: '${report.effectiveDayCount} 天',
      ),
      _InsightItem(
        icon: Icons.payments_outlined,
        label: '日均支出',
        value: MoneyUtils.format(
          report.avgDailyExpenseCents,
          currencyCode: currencyCode,
        ),
        valueColor: AppColors.expense,
      ),
      _InsightItem(
        icon: Icons.receipt_long_outlined,
        label: StatisticsStrings.transactionCount,
        value: '${report.transactionCount} 笔',
      ),
      _InsightItem(
        icon: Icons.savings_outlined,
        label: StatisticsStrings.savingsRate,
        value: savingsText,
        valueColor: AppColors.income,
      ),
      _InsightItem(
        icon: Icons.compare_arrows_rounded,
        label: '支出变化',
        value: changeText,
        valueColor: expenseChange == null
            ? null
            : (expenseChange >= 0 ? AppColors.expense : AppColors.income),
      ),
    ];

    return GlassSurface(
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            if (compact) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in items)
                    SizedBox(width: (constraints.maxWidth - 8) / 2, child: item),
                ],
              );
            }
            return Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 1,
                      height: 36,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: AppColors.divider.withValues(alpha: 0.5),
                    ),
                  Expanded(child: items[i]),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  const _InsightItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppThemeColors.textHint(context)),
          const SizedBox(width: 8),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: valueColor ?? AppThemeColors.textPrimary(context),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 统计页空状态（毛玻璃卡片）
class StatisticsEmptyState extends StatelessWidget {
  const StatisticsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassSurface(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppThemeColors.textHint(context),
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 可滚动 Tab 内容容器
class StatisticsTabScrollView extends StatelessWidget {
  const StatisticsTabScrollView({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 8),
        child: child,
      ),
    );
  }
}

class StatisticsSectionCard extends StatelessWidget {
  const StatisticsSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.accentColor,
    this.subtitle,
    this.trailing,
    this.expandChild = false,
    this.bodyHeight,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Color? accentColor;
  final String? subtitle;
  final Widget? trailing;
  final bool expandChild;

  /// 图表等内容区固定高度（用于 ScrollView 内，避免 Expanded 约束冲突）
  final double? bodyHeight;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primary;

    return GlassSurface(
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize:
              expandChild || bodyHeight != null ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: accent),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppThemeColors.textHint(context),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            if (expandChild)
              Expanded(child: child)
            else if (bodyHeight != null)
              SizedBox(height: bodyHeight, child: child)
            else
              child,
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.featured = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  featured ? 16 : 14,
                  14,
                  featured ? 16 : 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: featured ? 40 : 34,
                      height: featured ? 40 : 34,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: 0.2),
                            color.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: featured ? 20 : 17,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppThemeColors.textSecondary(context),
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                  fontSize: featured ? 18 : 16,
                                  letterSpacing: -0.2,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppThemeColors.textHint(context),
                                      fontSize: 11,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 毛玻璃胶囊按钮（筛选、分类选择等）
class StatisticsGlassChip extends StatelessWidget {
  const StatisticsGlassChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : GlassStyles.panelTint(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : GlassStyles.divider(context),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? Colors.white : AppThemeColors.textSecondary(context),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? Colors.white : AppThemeColors.textPrimary(context),
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? AppColors.primary : AppThemeColors.textSecondary(context),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}

class _FilterMenu<T> extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: GlassStyles.menuStyle(context),
      alignmentOffset: const Offset(0, 6),
      builder: (context, controller, _) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: GlassStyles.panelTint(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GlassStyles.divider(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$label · ',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppThemeColors.textHint(context),
                        ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Text(
                      itemLabel(value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more_rounded, size: 16),
                ],
              ),
            ),
          ),
        );
      },
      menuChildren: [
        for (final item in items)
          MenuItemButton(
            onPressed: () => onChanged(item),
            child: Text(itemLabel(item)),
          ),
      ],
    );
  }
}

class _SegmentPair extends StatelessWidget {
  const _SegmentPair({
    required this.leftLabel,
    required this.rightLabel,
    required this.leftSelected,
    required this.onLeft,
    required this.onRight,
  });

  final String leftLabel;
  final String rightLabel;
  final bool leftSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GlassStyles.panelTint(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GlassStyles.divider(context)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segmentButton(context, leftLabel, leftSelected, onLeft),
          _segmentButton(context, rightLabel, !leftSelected, onRight),
        ],
      ),
    );
  }

  Widget _segmentButton(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? Colors.white : AppThemeColors.textSecondary(context),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ),
      ),
    );
  }
}

class _ChartTypeSegments extends StatelessWidget {
  const _ChartTypeSegments({
    required this.types,
    required this.selected,
    required this.onChanged,
  });

  final List<StatisticsChartType> types;
  final StatisticsChartType selected;
  final ValueChanged<StatisticsChartType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GlassStyles.panelTint(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GlassStyles.divider(context)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < types.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            _chartButton(context, types[i]),
          ],
        ],
      ),
    );
  }

  Widget _chartButton(BuildContext context, StatisticsChartType type) {
    final selected = type == this.selected;
    final icon = switch (type) {
      StatisticsChartType.line => Icons.show_chart_rounded,
      StatisticsChartType.bar => Icons.bar_chart_rounded,
      StatisticsChartType.pie => Icons.pie_chart_outline_rounded,
      StatisticsChartType.radar => Icons.radar_rounded,
      StatisticsChartType.column => Icons.insert_chart_outlined_rounded,
      StatisticsChartType.bubble => Icons.bubble_chart_outlined,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(type),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : AppThemeColors.textSecondary(context),
              ),
              const SizedBox(width: 6),
              Text(
                chartTypeLabel(type),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? Colors.white : AppThemeColors.textSecondary(context),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatStatisticsRange(DateTime start, DateTime end) {
  if (AppDateUtils.formatDate(start) == AppDateUtils.formatDate(end)) {
    return DateFormat(StatisticsStrings.dateFormatPattern, 'zh_CN').format(start);
  }
  return '${AppDateUtils.formatDate(start)}${StatisticsStrings.dateRangeSep}${AppDateUtils.formatDate(end)}';
}
