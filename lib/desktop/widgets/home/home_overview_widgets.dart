import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/services/budget_service.dart';
import 'package:ezbookkeeping_desktop/core/services/statistics_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/home_dashboard_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_card.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/charts/budget_ring.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/home/home_dashboard_widgets.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/charts/statistics_charts.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/charts/yearly_trend_chart.dart';

class HomeSectionCard extends StatelessWidget {
  const HomeSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.onTitleTap,
    this.padding = const EdgeInsets.all(20),
    this.height,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTitleTap;
  final EdgeInsets padding;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTitleTap,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppThemeColors.textPrimary(context),
                                ),
                          ),
                          if (onTitleTap != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppThemeColors.textHint(context),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppThemeColors.textSecondary(context),
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 16),
        if (height != null) Expanded(child: child) else child,
      ],
    );

    final card = AppCard(
      padding: padding,
      child: content,
    );
    if (height != null) {
      return SizedBox(height: height, child: card);
    }
    return card;
  }
}

class HomePageHeader extends StatelessWidget {
  const HomePageHeader({
    super.key,
    required this.bookName,
    required this.hideAmount,
    required this.onToggleVisibility,
    required this.onRefresh,
    required this.onAddTransaction,
  });

  final String bookName;
  final bool hideAmount;
  final VoidCallback onToggleVisibility;
  final VoidCallback onRefresh;
  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greetingForHour(now.hour);
    final dateText = DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(now);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppThemeColors.textPrimary(context),
                    ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    dateText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppThemeColors.textSecondary(context),
                        ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      bookName,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: hideAmount ? '显示金额' : '隐藏金额',
          onPressed: onToggleVisibility,
          icon: Icon(
            hideAmount
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppThemeColors.textSecondary(context),
          ),
        ),
        IconButton(
          tooltip: '刷新',
          onPressed: onRefresh,
          icon: Icon(Icons.refresh, color: AppThemeColors.textSecondary(context)),
        ),
        const SizedBox(width: 4),
        FilledButton.icon(
          onPressed: onAddTransaction,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('记一笔'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      ],
    );
  }

  String _greetingForHour(int hour) {
    if (hour < 6) return '夜深了';
    if (hour < 12) return '早上好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }
}

class HomeNetWorthHeroCard extends StatelessWidget {
  const HomeNetWorthHeroCard({
    super.key,
    required this.assetSummary,
    required this.todayNetCents,
    required this.monthNetCents,
    required this.currencyCode,
    required this.hideAmount,
    required this.onViewAccounts,
  });

  final AssetSummary assetSummary;
  final int todayNetCents;
  final int monthNetCents;
  final String currencyCode;
  final bool hideAmount;
  final VoidCallback onViewAccounts;

  @override
  Widget build(BuildContext context) {
    String fmt(int cents) =>
        hideAmount ? '****' : MoneyUtils.formatSpaced(cents, currencyCode: currencyCode);

    return InkWell(
      onTap: onViewAccounts,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '净资产',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppThemeColors.textSecondary(context),
                      ),
                ),
                const Spacer(),
                Text(
                  '${assetSummary.accountCount} 个账户',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppThemeColors.textHint(context),
                      ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: AppThemeColors.textHint(context)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              fmt(assetSummary.netAssetsCents),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _MiniMetric(
                  label: '总资产',
                  value: fmt(assetSummary.totalAssetsCents),
                ),
                const SizedBox(width: 24),
                _MiniMetric(
                  label: '总负债',
                  value: fmt(assetSummary.totalLiabilitiesCents),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: '今日结余',
                    value: fmt(todayNetCents),
                    valueColor: todayNetCents >= 0
                        ? const Color(0xFFC04848)
                        : const Color(0xFF1B8C7E),
                  ),
                ),
                Expanded(
                  child: _MiniMetric(
                    label: '本月结余',
                    value: fmt(monthNetCents),
                    valueColor: monthNetCents >= 0
                        ? const Color(0xFFC04848)
                        : const Color(0xFF1B8C7E),
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

class HomeMonthInsightCard extends StatelessWidget {
  const HomeMonthInsightCard({
    super.key,
    required this.monthSummary,
    required this.savingsRate,
    required this.transactionCount,
    required this.currencyCode,
    required this.hideAmount,
    required this.onViewStatistics,
  });

  final PeriodSummary monthSummary;
  final double? savingsRate;
  final int transactionCount;
  final String currencyCode;
  final bool hideAmount;
  final VoidCallback onViewStatistics;

  @override
  Widget build(BuildContext context) {
    String fmt(int cents) =>
        hideAmount ? '****' : MoneyUtils.formatSpaced(cents, currencyCode: currencyCode);
    final monthName = DateFormat('M月', 'zh_CN').format(DateTime.now());

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$monthName收支概览',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 20),
          _FlowRow(
            label: '收入',
            value: fmt(monthSummary.incomeCents),
            color: const Color(0xFFC04848),
            icon: Icons.south_west,
          ),
          const SizedBox(height: 12),
          _FlowRow(
            label: '支出',
            value: fmt(monthSummary.expenseCents),
            color: const Color(0xFF1B8C7E),
            icon: Icons.north_east,
          ),
          const Spacer(),
          Row(
            children: [
              _InsightChip(
                label: '储蓄率',
                value: hideAmount
                    ? '**%'
                    : savingsRate == null
                        ? '--'
                        : '${savingsRate!.toStringAsFixed(1)}%',
              ),
              const SizedBox(width: 8),
              _InsightChip(
                label: '交易笔数',
                value: hideAmount ? '**' : '$transactionCount',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onViewStatistics,
              child: const Text('查看统计分析'),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeQuickActionsBar extends StatelessWidget {
  const HomeQuickActionsBar({
    super.key,
    required this.onAdd,
    required this.onTransactions,
    required this.onStatistics,
    required this.onAccounts,
  });

  final VoidCallback onAdd;
  final VoidCallback onTransactions;
  final VoidCallback onStatistics;
  final VoidCallback onAccounts;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            icon: Icons.add_circle_outline,
            label: '记一笔',
            color: AppColors.primary,
            onTap: onAdd,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.receipt_long_outlined,
            label: '交易详情',
            color: AppColors.transfer,
            onTap: onTransactions,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.pie_chart_outline,
            label: '统计分析',
            color: AppColors.income,
            onTap: onStatistics,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.account_balance_wallet_outlined,
            label: '账户管理',
            color: AppColors.expense,
            onTap: onAccounts,
          ),
        ),
      ],
    );
  }
}

class HomeDailyTrendSection extends StatelessWidget {
  const HomeDailyTrendSection({
    super.key,
    required this.points,
    required this.currencyCode,
  });

  final List<DailyTrendPoint> points;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return StatisticsIncomeExpenseChart(
      dailyPoints: points,
      monthlyPoints: const [],
      monthly: false,
      asBar: false,
      currencyCode: currencyCode,
    );
  }
}

class HomeExpenseCategorySection extends StatelessWidget {
  const HomeExpenseCategorySection({
    super.key,
    required this.items,
    required this.currencyCode,
  });

  final List<CategoryBreakdownItem> items;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final slices = buildSlicesFromCategories(items, maxSlices: 6);
    if (slices.isEmpty) {
      return Center(
        child: Text(
          '本月暂无支出分类数据',
          style: TextStyle(color: AppThemeColors.textHint(context)),
        ),
      );
    }
    return StatisticsPieChart(slices: slices, currencyCode: currencyCode);
  }
}

class HomeRecentTransactionsSection extends StatelessWidget {
  const HomeRecentTransactionsSection({
    super.key,
    required this.rows,
    required this.currencyCode,
    required this.hideAmount,
    required this.onViewAll,
    required this.onTapRow,
  });

  final List<TransactionRowData> rows;
  final String currencyCode;
  final bool hideAmount;
  final VoidCallback onViewAll;
  final ValueChanged<TransactionRowData> onTapRow;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppThemeColors.textHint(context).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              '还没有交易记录',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemeColors.textHint(context),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (context, index) {
        final row = rows[index];
        final amountColor = switch (row.transaction.type) {
          TransactionType.expense => const Color(0xFF1B8C7E),
          TransactionType.income => const Color(0xFFC04848),
          TransactionType.transfer => AppColors.transfer,
        };

        return InkWell(
          onTap: () => onTapRow(row),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    row.categoryIcon ?? Icons.label_outline,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        row.transaction.comment?.trim().isNotEmpty == true
                            ? row.transaction.comment!.trim()
                            : row.accountName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppThemeColors.textHint(context),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  hideAmount ? '****' : row.amountText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HomeBudgetOverviewSection extends StatelessWidget {
  const HomeBudgetOverviewSection({
    super.key,
    required this.budgets,
    required this.currencyCode,
    required this.hideAmount,
    required this.onManageBudgets,
  });

  final List<BudgetWithProgress> budgets;
  final String currencyCode;
  final bool hideAmount;
  final VoidCallback onManageBudgets;

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 40,
              color: AppThemeColors.textHint(context).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              '尚未设置预算',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemeColors.textHint(context),
                  ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onManageBudgets,
              child: const Text('去设置预算'),
            ),
          ],
        ),
      );
    }

    final visible = budgets.take(3).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in visible)
          Expanded(
            child: BudgetRing(
              progress: item.progress,
              rawProgress: item.rawProgress,
              label: '已用',
              spentText: hideAmount
                  ? '****'
                  : MoneyUtils.format(item.spentCents, currencyCode: currencyCode),
              budgetText: hideAmount
                  ? '****'
                  : MoneyUtils.format(
                      item.budget.amount,
                      currencyCode: currencyCode,
                    ),
              isOverBudget: item.isOverBudget,
              size: 96,
            ),
          ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppThemeColors.textSecondary(context),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppThemeColors.textPrimary(context),
              ),
        ),
      ],
    );
  }
}

class _FlowRow extends StatelessWidget {
  const _FlowRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemeColors.textSecondary(context),
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppThemeColors.cardFill(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppThemeColors.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppThemeColors.textHint(context),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: GlassSurface(
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppThemeColors.textPrimary(context),
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
