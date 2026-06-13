import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/services/statistics_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/loan_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/statistics_page_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/statistics_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/charts/budget_ring.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/charts/statistics_charts.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/home/home_dashboard_widgets.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/statistics/statistics_account_panel.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/statistics/statistics_dashboard_widgets.dart';

/// 根据当前 Tab 渲染统计内容区
class StatisticsTabContent extends ConsumerWidget {
  const StatisticsTabContent({
    super.key,
    required this.pageState,
    required this.report,
    required this.accounts,
    required this.assetSummary,
    required this.currencyCode,
  });

  final StatisticsPageState pageState;
  final StatisticsFullReport report;
  final List<Account> accounts;
  final AssetSummary assetSummary;
  final String currencyCode;

  bool get _useMonthlyTrend =>
      pageState.trendMonthly || !report.supportsDailyTrend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (pageState.mainTab) {
      StatisticsMainTab.overview => StatisticsOverviewTab(
          pageState: pageState,
          report: report,
          assetSummary: assetSummary,
          currencyCode: currencyCode,
          useMonthlyTrend: _useMonthlyTrend,
        ),
      StatisticsMainTab.trend => StatisticsTrendTab(
          pageState: pageState,
          report: report,
          currencyCode: currencyCode,
          useMonthlyTrend: _useMonthlyTrend,
        ),
      StatisticsMainTab.category => StatisticsCategoryTab(
          pageState: pageState,
          report: report,
          currencyCode: currencyCode,
        ),
      StatisticsMainTab.account => StatisticsAccountPanel(
          accounts: accounts,
          report: report,
          assetSummary: assetSummary,
          pageState: pageState,
          currencyCode: currencyCode,
        ),
      StatisticsMainTab.budget => StatisticsBudgetTab(
          currencyCode: currencyCode,
        ),
    };
  }
}

/// 总览：摘要条 + KPI + 趋势 + 分类饼图 + 排行
class StatisticsOverviewTab extends ConsumerWidget {
  const StatisticsOverviewTab({
    super.key,
    required this.pageState,
    required this.report,
    required this.assetSummary,
    required this.currencyCode,
    required this.useMonthlyTrend,
  });

  final StatisticsPageState pageState;
  final StatisticsFullReport report;
  final AssetSummary assetSummary;
  final String currencyCode;
  final bool useMonthlyTrend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetKpi = ref.watch(statisticsBudgetKpiProvider).valueOrNull;
    final expenseItems = _sortedCategories(report.expenseByCategory);
    final incomeItems = _sortedCategories(report.incomeByCategory);
    final expenseRows = _toRankingRows(expenseItems, limit: 5);
    final incomeRows = _toRankingRows(incomeItems, limit: 5);
    final expenseSlices = buildSlicesFromCategories(expenseItems, maxSlices: 6);
    final incomeSlices = buildSlicesFromCategories(incomeItems, maxSlices: 6);
    final trendSubtitle = useMonthlyTrend ? '按月汇总' : '按日汇总';

    return StatisticsTabScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatisticsPeriodInsightBar(
            report: report,
            currencyCode: currencyCode,
          ),
          const SizedBox(height: 14),
          StatisticsKpiGrid(
            report: report,
            assetSummary: assetSummary,
            currencyCode: currencyCode,
            budgetKpi: budgetKpi,
          ),
          const SizedBox(height: 16),
          StatisticsSectionCard(
            title: '收支趋势',
            subtitle: trendSubtitle,
            icon: Icons.show_chart_rounded,
            accentColor: AppColors.primary,
            bodyHeight: 260,
            child: RepaintBoundary(
              child: StatisticsIncomeExpenseChart(
                dailyPoints: report.dailyTrend,
                monthlyPoints: report.monthlyTrend,
                monthly: useMonthlyTrend,
                asBar: pageState.chartType == StatisticsChartType.bar,
                currencyCode: currencyCode,
              ),
            ),
          ),
          if (expenseSlices.isNotEmpty || incomeSlices.isNotEmpty) ...[
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 900;
                Widget pieCard({
                  required String title,
                  required Color accent,
                  required List<StatisticsBreakdownSlice> slices,
                }) {
                  return StatisticsSectionCard(
                    title: title,
                    icon: Icons.pie_chart_outline_rounded,
                    accentColor: accent,
                    bodyHeight: 220,
                    child: slices.isEmpty
                        ? const _MiniEmptyHint()
                        : RepaintBoundary(
                            child: StatisticsPieChart(
                              slices: slices,
                              currencyCode: currencyCode,
                            ),
                          ),
                  );
                }

                final expenseCard = pieCard(
                  title: '支出构成',
                  accent: AppColors.expense,
                  slices: expenseSlices,
                );
                final incomeCard = pieCard(
                  title: '收入构成',
                  accent: AppColors.income,
                  slices: incomeSlices,
                );

                if (stacked) {
                  return Column(
                    children: [
                      expenseCard,
                      const SizedBox(height: 16),
                      incomeCard,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: expenseCard),
                    const SizedBox(width: 16),
                    Expanded(child: incomeCard),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 900;
              final expenseRanking = StatisticsRankingTable(
                title: '支出 Top 5',
                rows: expenseRows,
                currencyCode: currencyCode,
                accentColor: AppColors.expense,
              );
              final incomeRanking = StatisticsRankingTable(
                title: '收入 Top 5',
                rows: incomeRows,
                currencyCode: currencyCode,
                accentColor: AppColors.income,
              );

              if (stacked) {
                return Column(
                  children: [
                    expenseRanking,
                    const SizedBox(height: 16),
                    incomeRanking,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: expenseRanking),
                  const SizedBox(width: 16),
                  Expanded(child: incomeRanking),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 收支趋势：折线 / 柱状 / 气泡
class StatisticsTrendTab extends ConsumerWidget {
  const StatisticsTrendTab({
    super.key,
    required this.pageState,
    required this.report,
    required this.currencyCode,
    required this.useMonthlyTrend,
  });

  final StatisticsPageState pageState;
  final StatisticsFullReport report;
  final String currencyCode;
  final bool useMonthlyTrend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pageState.chartType == StatisticsChartType.bubble) {
      return _BubbleTrendView(
        pageState: pageState,
        report: report,
        currencyCode: currencyCode,
      );
    }

    final chartTitle = switch (pageState.chartType) {
      StatisticsChartType.bar => '收支柱状图',
      _ => '收支折线图',
    };
    final subtitle = useMonthlyTrend ? '按月对比收入与支出' : '按日对比收入与支出';

    return StatisticsSectionCard(
      title: chartTitle,
      subtitle: subtitle,
      icon: pageState.chartType == StatisticsChartType.bar
          ? Icons.bar_chart_rounded
          : Icons.show_chart_rounded,
      accentColor: AppColors.primary,
      expandChild: true,
      child: RepaintBoundary(
        child: StatisticsIncomeExpenseChart(
          dailyPoints: report.dailyTrend,
          monthlyPoints: report.monthlyTrend,
          monthly: useMonthlyTrend,
          asBar: pageState.chartType == StatisticsChartType.bar,
          currencyCode: currencyCode,
        ),
      ),
    );
  }
}

class _BubbleTrendView extends ConsumerWidget {
  const _BubbleTrendView({
    required this.pageState,
    required this.report,
    required this.currencyCode,
  });

  final StatisticsPageState pageState;
  final StatisticsFullReport report;
  final String currencyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (report.expenseByCategory.isEmpty) {
      return const StatisticsEmptyState(
        icon: Icons.bubble_chart_outlined,
        title: '暂无支出分类数据',
        subtitle: '添加支出账单后即可查看分类气泡趋势',
      );
    }

    final selectedId = pageState.selectedCategoryId ??
        report.expenseByCategory.first.categoryId;
    final matched = report.expenseByCategory
        .where((c) => c.categoryId == selectedId);
    final categoryName =
        matched.isEmpty ? '支出分类' : matched.first.categoryName;
    final trendAsync = ref.watch(statisticsCategoryTrendProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSurface(
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择支出分类',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in report.expenseByCategory)
                      StatisticsGlassChip(
                        label: item.categoryName,
                        selected: selectedId == item.categoryId,
                        onTap: () => ref
                            .read(statisticsPageProvider.notifier)
                            .selectCategory(item.categoryId),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: StatisticsSectionCard(
            title: '分类月度气泡图',
            subtitle: categoryName,
            icon: Icons.bubble_chart_outlined,
            accentColor: AppColors.expense,
            expandChild: true,
            child: trendAsync.when(
              skipLoadingOnReload: true,
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => const Center(child: Text('加载失败')),
              data: (points) => RepaintBoundary(
                child: StatisticsBubbleTrendChart(
                  points: points,
                  seriesLabel: categoryName,
                  currencyCode: currencyCode,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 分类分析：饼图 / 柱状 / 雷达 + 完整排行
class StatisticsCategoryTab extends StatelessWidget {
  const StatisticsCategoryTab({
    super.key,
    required this.pageState,
    required this.report,
    required this.currencyCode,
  });

  final StatisticsPageState pageState;
  final StatisticsFullReport report;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final isExpense = pageState.categoryMode == StatisticsCategoryMode.expense;
    final items = sortBreakdown<CategoryBreakdownItem>(
      items: isExpense ? report.expenseByCategory : report.incomeByCategory,
      order: pageState.sortOrder,
      amountOf: (i) => i.amountCents,
      nameOf: (i) => i.categoryName,
      sortOrderOf: (i) => i.sortOrder,
    );
    final slices = buildSlicesFromCategories(items);
    final rows = _toRankingRows(items);
    final accent = isExpense ? AppColors.expense : AppColors.income;
    final chartTitle = switch (pageState.chartType) {
      StatisticsChartType.bar => isExpense ? '支出柱状图' : '收入柱状图',
      StatisticsChartType.radar => isExpense ? '支出雷达图' : '收入雷达图',
      _ => isExpense ? '支出饼图' : '收入饼图',
    };

    if (items.isEmpty) {
      return StatisticsEmptyState(
        icon: Icons.category_outlined,
        title: isExpense ? '本期暂无支出分类' : '本期暂无收入分类',
        subtitle: '调整筛选条件或添加账单后查看',
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: StatisticsSectionCard(
            title: chartTitle,
            icon: _chartIcon(pageState.chartType),
            accentColor: accent,
            expandChild: true,
            child: RepaintBoundary(
              child: _CategoryChart(
                chartType: pageState.chartType,
                slices: slices,
                currencyCode: currencyCode,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: StatisticsRankingTable(
            title: isExpense ? '支出分类排行' : '收入分类排行',
            rows: rows,
            currencyCode: currencyCode,
            accentColor: accent,
            fillHeight: true,
          ),
        ),
      ],
    );
  }

  IconData _chartIcon(StatisticsChartType type) => switch (type) {
        StatisticsChartType.bar => Icons.bar_chart_rounded,
        StatisticsChartType.radar => Icons.radar_rounded,
        _ => Icons.pie_chart_outline_rounded,
      };
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({
    required this.chartType,
    required this.slices,
    required this.currencyCode,
  });

  final StatisticsChartType chartType;
  final List<StatisticsBreakdownSlice> slices;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return switch (chartType) {
      StatisticsChartType.pie => StatisticsPieChart(
          slices: slices,
          currencyCode: currencyCode,
        ),
      StatisticsChartType.bar => StatisticsBarChart(
          slices: slices,
          currencyCode: currencyCode,
        ),
      StatisticsChartType.radar => StatisticsRadarChart(slices: slices),
      _ => StatisticsPieChart(
          slices: slices,
          currencyCode: currencyCode,
        ),
    };
  }
}

/// 预算执行：环形进度网格
class StatisticsBudgetTab extends ConsumerWidget {
  const StatisticsBudgetTab({
    super.key,
    required this.currencyCode,
  });

  final String currencyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetProgressListProvider);

    return budgetsAsync.when(
      skipLoadingOnReload: true,
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (_, __) => const Center(child: Text('加载预算失败')),
      data: (budgets) {
        if (budgets.isEmpty) {
          return const StatisticsEmptyState(
            icon: Icons.donut_large_outlined,
            title: '暂无预算',
            subtitle: '可在「预算管理」中设置月度或分类预算',
          );
        }

        final overCount = budgets.where((b) => b.isOverBudget).length;
        final totalBudget =
            budgets.fold<int>(0, (s, b) => s + b.budget.amount);
        final totalSpent =
            budgets.fold<int>(0, (s, b) => s + b.spentCents);
        final usagePercent =
            totalBudget > 0 ? totalSpent / totalBudget * 100 : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassSurface(
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _BudgetMetric(
                        label: '预算总额',
                        value: MoneyUtils.format(
                          totalBudget,
                          currencyCode: currencyCode,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppColors.divider.withValues(alpha: 0.5),
                    ),
                    Expanded(
                      child: _BudgetMetric(
                        label: '已使用',
                        value: MoneyUtils.format(
                          totalSpent,
                          currencyCode: currencyCode,
                        ),
                        valueColor: AppColors.expense,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppColors.divider.withValues(alpha: 0.5),
                    ),
                    Expanded(
                      child: _BudgetMetric(
                        label: '总使用率',
                        value: '${usagePercent.toStringAsFixed(1)}%',
                        valueColor: usagePercent > 100
                            ? AppColors.expense
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            GlassSurface(
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.donut_large_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '共 ${budgets.length} 项预算',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    if (overCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$overCount 项已超支',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.expense,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 8),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisExtent: 248,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: budgets.length,
                itemBuilder: (context, index) {
                  final item = budgets[index];
                  final remaining = item.budget.amount - item.spentCents;
                  final accent =
                      item.isOverBudget ? AppColors.expense : AppColors.primary;

                  return GlassSurface(
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.categoryName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      item.isOverBudget
                                          ? '已超支 ${MoneyUtils.format(remaining.abs(), currencyCode: currencyCode)}'
                                          : '剩余 ${MoneyUtils.format(remaining, currencyCode: currencyCode)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: item.isOverBudget
                                                ? AppColors.expense
                                                : AppColors.textHint,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Center(
                              child: BudgetRing(
                                progress: item.progress,
                                rawProgress: item.rawProgress,
                                label: '已用',
                                spentText: MoneyUtils.format(
                                  item.spentCents,
                                  currencyCode: currencyCode,
                                ),
                                budgetText: MoneyUtils.format(
                                  item.budget.amount,
                                  currencyCode: currencyCode,
                                ),
                                isOverBudget: item.isOverBudget,
                                size: 96,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BudgetMetric extends StatelessWidget {
  const _BudgetMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _MiniEmptyHint extends StatelessWidget {
  const _MiniEmptyHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '暂无数据',
        style: TextStyle(color: AppColors.textHint),
      ),
    );
  }
}

List<CategoryBreakdownItem> _sortedCategories(
  List<CategoryBreakdownItem> items,
) {
  return sortBreakdown<CategoryBreakdownItem>(
    items: items,
    order: StatisticsSortOrder.amount,
    amountOf: (i) => i.amountCents,
    nameOf: (i) => i.categoryName,
    sortOrderOf: (i) => i.sortOrder,
  );
}

List<({String name, int amountCents, double percentage})> _toRankingRows(
  List<CategoryBreakdownItem> items, {
  int? limit,
}) {
  final list = items
      .map(
        (i) => (
          name: i.categoryName,
          amountCents: i.amountCents,
          percentage: i.percentage,
        ),
      )
      .toList();
  if (limit != null && list.length > limit) {
    return list.take(limit).toList();
  }
  return list;
}
