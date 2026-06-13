import 'package:ezbookkeeping_desktop/core/services/statistics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StatisticsMainTab { overview, trend, category, account, budget }

enum StatisticsCategoryMode { expense, income }

enum StatisticsChartType { pie, bar, radar, line, column, bubble }

enum StatisticsSortOrder { displayOrder, amount, name }

class StatisticsPageState {
  const StatisticsPageState({
    this.mainTab = StatisticsMainTab.overview,
    this.categoryMode = StatisticsCategoryMode.expense,
    this.chartType = StatisticsChartType.pie,
    this.sortOrder = StatisticsSortOrder.amount,
    this.trendMonthly = false,
    this.selectedCategoryId,
    this.selectedAccountFlowId,
    this.assetMetric = StatisticsAssetMetric.netAssets,
    this.focusYear,
  });

  final StatisticsMainTab mainTab;
  final StatisticsCategoryMode categoryMode;
  final StatisticsChartType chartType;
  final StatisticsSortOrder sortOrder;
  final bool trendMonthly;

  /// 分类/趋势 drill-down
  final int? selectedCategoryId;
  final int? selectedAccountFlowId;
  final StatisticsAssetMetric assetMetric;
  final int? focusYear;

  int resolveYear(DateTime now) => focusYear ?? now.year;

  StatisticsPageState copyWith({
    StatisticsMainTab? mainTab,
    StatisticsCategoryMode? categoryMode,
    StatisticsChartType? chartType,
    StatisticsSortOrder? sortOrder,
    bool? trendMonthly,
    int? selectedCategoryId,
    bool clearCategoryId = false,
    int? selectedAccountFlowId,
    bool clearAccountFlowId = false,
    StatisticsAssetMetric? assetMetric,
    int? focusYear,
    bool clearFocusYear = false,
  }) {
    return StatisticsPageState(
      mainTab: mainTab ?? this.mainTab,
      categoryMode: categoryMode ?? this.categoryMode,
      chartType: chartType ?? this.chartType,
      sortOrder: sortOrder ?? this.sortOrder,
      trendMonthly: trendMonthly ?? this.trendMonthly,
      selectedCategoryId:
          clearCategoryId ? null : (selectedCategoryId ?? this.selectedCategoryId),
      selectedAccountFlowId: clearAccountFlowId
          ? null
          : (selectedAccountFlowId ?? this.selectedAccountFlowId),
      assetMetric: assetMetric ?? this.assetMetric,
      focusYear: clearFocusYear ? null : (focusYear ?? this.focusYear),
    );
  }
}

class StatisticsPageNotifier extends StateNotifier<StatisticsPageState> {
  StatisticsPageNotifier() : super(const StatisticsPageState());

  void setMainTab(StatisticsMainTab tab) {
    final defaultChart = switch (tab) {
      StatisticsMainTab.overview => StatisticsChartType.line,
      StatisticsMainTab.trend => StatisticsChartType.line,
      StatisticsMainTab.category => StatisticsChartType.pie,
      StatisticsMainTab.account => StatisticsChartType.pie,
      StatisticsMainTab.budget => StatisticsChartType.bar,
    };
    state = state.copyWith(mainTab: tab, chartType: defaultChart);
  }

  void setCategoryMode(StatisticsCategoryMode mode) {
    state = state.copyWith(categoryMode: mode);
  }

  void setChartType(StatisticsChartType type) {
    state = state.copyWith(chartType: type);
  }

  void setSortOrder(StatisticsSortOrder order) {
    state = state.copyWith(sortOrder: order);
  }

  void setTrendMonthly(bool monthly) {
    state = state.copyWith(trendMonthly: monthly);
  }

  void selectCategory(int? categoryId) {
    state = state.copyWith(
      selectedCategoryId: categoryId,
      clearCategoryId: categoryId == null,
    );
  }

  void selectAccountFlow(int? accountId) {
    state = state.copyWith(
      selectedAccountFlowId: accountId,
      clearAccountFlowId: accountId == null,
    );
  }

  void setAssetMetric(StatisticsAssetMetric metric) {
    state = state.copyWith(assetMetric: metric);
  }

  void shiftYear(int delta) {
    final current = state.resolveYear(DateTime.now());
    state = state.copyWith(focusYear: current + delta);
  }

  void resetYear() {
    state = state.copyWith(clearFocusYear: true);
  }
}

final statisticsPageProvider =
    StateNotifierProvider<StatisticsPageNotifier, StatisticsPageState>(
  (ref) => StatisticsPageNotifier(),
);

List<StatisticsChartType> chartTypesForTab(StatisticsMainTab tab) {
  return switch (tab) {
    StatisticsMainTab.overview => [
        StatisticsChartType.line,
        StatisticsChartType.bar,
      ],
    StatisticsMainTab.trend => [
        StatisticsChartType.line,
        StatisticsChartType.bar,
        StatisticsChartType.bubble,
      ],
    StatisticsMainTab.category => [
        StatisticsChartType.pie,
        StatisticsChartType.bar,
        StatisticsChartType.radar,
      ],
    StatisticsMainTab.account => [
        StatisticsChartType.pie,
        StatisticsChartType.bar,
        StatisticsChartType.column,
      ],
    StatisticsMainTab.budget => [StatisticsChartType.bar],
  };
}

String chartTypeLabel(StatisticsChartType type) {
  return switch (type) {
    StatisticsChartType.pie => '饼图',
    StatisticsChartType.bar => '条形图',
    StatisticsChartType.radar => '雷达图',
    StatisticsChartType.line => '折线图',
    StatisticsChartType.column => '柱状图',
    StatisticsChartType.bubble => '气泡图',
  };
}

String mainTabLabel(StatisticsMainTab tab) {
  return switch (tab) {
    StatisticsMainTab.overview => '总览',
    StatisticsMainTab.trend => '收支趋势',
    StatisticsMainTab.category => '分类分析',
    StatisticsMainTab.account => '账户资产',
    StatisticsMainTab.budget => '预算执行',
  };
}
