import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/home_dashboard_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/add_transaction_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/home/home_dashboard_widgets.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/home/home_overview_widgets.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/transaction_detail_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/charts/yearly_trend_chart.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _hideAmount = false;

  String _amount(int cents, String currencyCode) {
    if (_hideAmount) return '****';
    return MoneyUtils.formatSpaced(cents, currencyCode: currencyCode);
  }

  Future<void> _openTransactionDetail(TransactionRowData row) async {
    final changed = await showTransactionDetailDialog(context, row: row);
    if (changed == true && mounted) {
      refreshHomeDashboard(ref);
    }
  }

  void _goTransactions(HomePeriodScope scope) {
    applyHomePeriodFilter(ref, scope);
    context.go('/transactions');
  }

  @override
  Widget build(BuildContext context) {
    final currencyCode = ref.watch(currencyCodeProvider);
    final dashboardAsync = ref.watch(homeDashboardProvider);
    final now = DateTime.now();

    return dashboardAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 16),
                Text(
                  '加载总览数据失败',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => refreshHomeDashboard(ref),
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (data) {
        final stats = data.stats;
        final weekStartsOn = ref.watch(weekStartsOnProvider);
        final monthStartDay = ref.watch(monthStartDayProvider);
        final showWeekCard = ref.watch(settingsProvider).homeWeekCard;
        final weekStart = AppDateUtils.startOfWeek(
          now,
          weekStartsOn: weekStartsOn,
        );
        final weekEnd = AppDateUtils.endOfWeek(
          now,
          weekStartsOn: weekStartsOn,
        );
        final monthStart = AppDateUtils.startOfBillingMonth(
          now,
          monthStartDay: monthStartDay,
        );
        final monthEnd = AppDateUtils.endOfBillingMonth(
          now,
          monthStartDay: monthStartDay,
        );
        final bookName = data.activeBook?.name ?? '默认账本';

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomePageHeader(
                bookName: bookName,
                hideAmount: _hideAmount,
                onToggleVisibility: () =>
                    setState(() => _hideAmount = !_hideAmount),
                onRefresh: () => refreshHomeDashboard(ref),
                onAddTransaction: () async {
                  final saved = await showAddTransactionDialog(context);
                  if (saved == true && mounted) {
                    refreshHomeDashboard(ref);
                  }
                },
              ),
              const SizedBox(height: 20),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 11,
                      child: HomeNetWorthHeroCard(
                        assetSummary: data.assetSummary,
                        todayNetCents: stats.today.netCents,
                        monthNetCents: stats.month.netCents,
                        currencyCode: currencyCode,
                        hideAmount: _hideAmount,
                        onViewAccounts: () => context.go('/accounts'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 9,
                      child: HomeMonthInsightCard(
                        monthSummary: stats.month,
                        savingsRate: data.monthSavingsRate,
                        transactionCount: data.monthTransactionCount,
                        currencyCode: currencyCode,
                        hideAmount: _hideAmount,
                        onViewStatistics: () => context.go('/statistics'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              HomeQuickActionsBar(
                onAdd: () async {
                  final saved = await showAddTransactionDialog(context);
                  if (saved == true && mounted) {
                    refreshHomeDashboard(ref);
                  }
                },
                onTransactions: () => context.go('/transactions'),
                onStatistics: () => context.go('/statistics'),
                onAccounts: () => context.go('/accounts'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: Row(
                  children: [
                    Expanded(
                      child: HomePeriodCard(
                        title: '今天',
                        incomeText: _amount(
                          stats.today.incomeCents,
                          currencyCode,
                        ),
                        expenseText: _amount(
                          stats.today.expenseCents,
                          currencyCode,
                        ),
                        periodLabel: DateFormat('yyyy年M月d日', 'zh_CN').format(now),
                        iconLetter: 'd',
                        onTap: () => _goTransactions(HomePeriodScope.today),
                      ),
                    ),
                    if (showWeekCard) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: HomePeriodCard(
                          title: '本周',
                          incomeText:
                              _amount(stats.week.incomeCents, currencyCode),
                          expenseText: _amount(
                            stats.week.expenseCents,
                            currencyCode,
                          ),
                          periodLabel: formatHomePeriodLabel(weekStart, weekEnd),
                          iconLetter: 'w',
                          onTap: () => _goTransactions(HomePeriodScope.week),
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Expanded(
                      child: HomePeriodCard(
                        title: '本月',
                        incomeText: _amount(
                          stats.month.incomeCents,
                          currencyCode,
                        ),
                        expenseText: _amount(
                          stats.month.expenseCents,
                          currencyCode,
                        ),
                        periodLabel: formatHomePeriodLabel(monthStart, monthEnd),
                        iconLetter: 'm',
                        onTap: () => _goTransactions(HomePeriodScope.month),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HomePeriodCard(
                        title: '今年',
                        incomeText: _amount(stats.year.incomeCents, currencyCode),
                        expenseText: _amount(
                          stats.year.expenseCents,
                          currencyCode,
                        ),
                        periodLabel: DateFormat('yyyy年', 'zh_CN').format(now),
                        iconLetter: 'y',
                        icon: Icons.layers_outlined,
                        onTap: () => _goTransactions(HomePeriodScope.year),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: HomeSectionCard(
                        height: 300,
                        title: '本月收支趋势',
                        subtitle: '按日汇总',
                        onTitleTap: () => context.go('/statistics'),
                        child: HomeDailyTrendSection(
                          points: data.monthOverview.trend,
                          currencyCode: currencyCode,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: HomeSectionCard(
                        height: 300,
                        title: '本月支出分类',
                        subtitle: 'Top 分类占比',
                        onTitleTap: () => context.go('/statistics'),
                        child: HomeExpenseCategorySection(
                          items: data.monthOverview.expenseByCategory,
                          currencyCode: currencyCode,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 320,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: HomeSectionCard(
                        height: 320,
                        title: '最近交易',
                        subtitle: '最新 8 笔',
                        onTitleTap: () => context.go('/transactions'),
                        trailing: TextButton(
                          onPressed: () => context.go('/transactions'),
                          child: const Text('查看全部'),
                        ),
                        child: HomeRecentTransactionsSection(
                          rows: data.recentTransactions,
                          currencyCode: currencyCode,
                          hideAmount: _hideAmount,
                          onViewAll: () => context.go('/transactions'),
                          onTapRow: _openTransactionDetail,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: HomeSectionCard(
                        height: 320,
                        title: '预算执行',
                        subtitle: '本月预算进度',
                        onTitleTap: () => context.go('/budgets'),
                        trailing: TextButton(
                          onPressed: () => context.go('/budgets'),
                          child: const Text('管理'),
                        ),
                        child: HomeBudgetOverviewSection(
                          budgets: data.budgets,
                          currencyCode: currencyCode,
                          hideAmount: _hideAmount,
                          onManageBudgets: () => context.go('/budgets'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              HomeSectionCard(
                height: 340,
                title: '年度收支趋势',
                subtitle: '${now.year} 年各月收入与支出',
                onTitleTap: () => context.go('/statistics'),
                child: YearlyTrendChart(
                  points: stats.yearlyTrend,
                  currencyCode: currencyCode,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
