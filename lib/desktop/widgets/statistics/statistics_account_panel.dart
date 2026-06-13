import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/services/statistics_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/account_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/statistics_page_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/statistics_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/account/account_list_panel.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/forms/default_accounts_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/home/home_dashboard_widgets.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/charts/statistics_charts.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/statistics/statistics_dashboard_widgets.dart';

/// 账户资产 Tab：左侧账户列表，右侧资产统计图表
class StatisticsAccountPanel extends ConsumerStatefulWidget {
  const StatisticsAccountPanel({
    super.key,
    required this.accounts,
    required this.report,
    required this.assetSummary,
    required this.pageState,
    required this.currencyCode,
  });

  final List<Account> accounts;
  final StatisticsFullReport report;
  final AssetSummary assetSummary;
  final StatisticsPageState pageState;
  final String currencyCode;

  @override
  ConsumerState<StatisticsAccountPanel> createState() =>
      _StatisticsAccountPanelState();
}

class _StatisticsAccountPanelState extends ConsumerState<StatisticsAccountPanel> {
  int? get _selectedAccountId {
    final selected = widget.pageState.selectedAccountFlowId;
    if (selected != null &&
        widget.accounts.any((a) => a.id == selected)) {
      return selected;
    }
    if (widget.accounts.isEmpty) return null;
    return widget.accounts.first.id;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pageState.chartType == StatisticsChartType.column) {
      return _AssetColumnView(
        pageState: widget.pageState,
        assetSummary: widget.assetSummary,
        currencyCode: widget.currencyCode,
      );
    }

    if (widget.accounts.isEmpty) {
      return Center(
        child: AccountEmptyState(
          onAddDefaults: () => _openDefaultAccounts(context),
        ),
      );
    }

    final isPie = widget.pageState.chartType == StatisticsChartType.pie;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AccountSidebarPanel(
          accounts: widget.accounts,
          summary: widget.assetSummary,
          currencyCode: widget.currencyCode,
          selectedAccountId: _selectedAccountId,
          hideAmount: false,
          onAccountSelected: (id) {
            ref.read(statisticsPageProvider.notifier).selectAccountFlow(id);
          },
        ),
        const SizedBox(width: 16),
        Expanded(child: _buildChartPanel(context, isPie: isPie)),
      ],
    );
  }

  Widget _buildChartPanel(BuildContext context, {required bool isPie}) {
    final balanceItems = sortBreakdown<AccountBreakdownItem>(
      items: widget.report.accountBalances,
      order: widget.pageState.sortOrder,
      amountOf: (i) => i.amountCents,
      nameOf: (i) => i.accountName,
      sortOrderOf: (i) => i.sortOrder,
    );
    final expenseFlow = sortBreakdown<AccountFlowItem>(
      items: widget.report.expenseByAccount,
      order: widget.pageState.sortOrder,
      amountOf: (i) => i.amountCents,
      nameOf: (i) => i.accountName,
      sortOrderOf: (i) => i.sortOrder,
    );

    final slices = isPie
        ? buildSlicesFromAccounts(balanceItems)
        : buildSlicesFromAccountFlow(expenseFlow);

    if (slices.isEmpty) {
      return StatisticsEmptyState(
        icon: isPie ? Icons.pie_chart_outline_rounded : Icons.bar_chart_rounded,
        title: isPie ? '暂无账户余额数据' : '本期暂无账户支出',
        subtitle: isPie ? null : '调整筛选条件后查看各账户支出分布',
      );
    }

    return StatisticsSectionCard(
      title: isPie ? '账户余额构成' : '账户支出排行',
      subtitle: isPie ? '各账户当前余额占比' : '筛选期内各账户支出金额',
      icon: isPie ? Icons.pie_chart_outline_rounded : Icons.bar_chart_rounded,
      accentColor: isPie ? AppColors.primary : AppColors.expense,
      expandChild: true,
      trailing: IconButton(
        tooltip: '刷新',
        onPressed: () =>
            ref.read(transactionRefreshProvider.notifier).state++,
        icon: const Icon(Icons.refresh, size: 20),
        color: AppColors.textSecondary,
      ),
      child: RepaintBoundary(
        child: isPie
            ? StatisticsPieChart(
                slices: slices,
                currencyCode: widget.currencyCode,
              )
            : StatisticsBarChart(
                slices: slices,
                currencyCode: widget.currencyCode,
              ),
      ),
    );
  }

  Future<void> _openDefaultAccounts(BuildContext context) async {
    final existingNames = widget.accounts.map((a) => a.name).toSet();
    final saved = await showDefaultAccountsDialog(
      context,
      existingNames: existingNames,
    );
    if (saved && context.mounted) {
      refreshAccounts(ref);
      ref.read(transactionRefreshProvider.notifier).state++;
    }
  }
}

class _AssetColumnView extends ConsumerWidget {
  const _AssetColumnView({
    required this.pageState,
    required this.assetSummary,
    required this.currencyCode,
  });

  final StatisticsPageState pageState;
  final AssetSummary assetSummary;
  final String currencyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(statisticsAssetTrendProvider);
    final metricLabel = switch (pageState.assetMetric) {
      StatisticsAssetMetric.totalAssets => '账户总资产',
      StatisticsAssetMetric.totalLiabilities => '账户总负债',
      StatisticsAssetMetric.netAssets => '净资产',
    };
    final metricValue = switch (pageState.assetMetric) {
      StatisticsAssetMetric.totalAssets => assetSummary.totalAssetsCents,
      StatisticsAssetMetric.totalLiabilities => assetSummary.totalLiabilitiesCents,
      StatisticsAssetMetric.netAssets => assetSummary.netAssetsCents,
    };

    return StatisticsSectionCard(
      title: metricLabel,
      subtitle: '当前 ${MoneyUtils.formatSpaced(metricValue, currencyCode: currencyCode)}',
      icon: Icons.insert_chart_outlined_rounded,
      accentColor: AppColors.primary,
      expandChild: true,
      child: trendAsync.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => const Center(child: Text('加载失败')),
        data: (points) => RepaintBoundary(
          child: StatisticsAssetColumnChart(
            points: points,
            seriesLabel: metricLabel,
            currencyCode: currencyCode,
          ),
        ),
      ),
    );
  }
}
