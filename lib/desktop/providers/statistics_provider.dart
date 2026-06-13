import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/statistics_query.dart';
import 'package:ezbookkeeping_desktop/core/services/budget_service.dart';
import 'package:ezbookkeeping_desktop/core/services/statistics_service.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/statistics_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/statistics_page_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/home/home_dashboard_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetKpiSummary {
  const BudgetKpiSummary({
    required this.label,
    required this.spentCents,
    required this.budgetCents,
    required this.isOverBudget,
  });

  final String label;
  final int spentCents;
  final int budgetCents;
  final bool isOverBudget;

  double get usagePercent =>
      budgetCents > 0 ? (spentCents / budgetCents * 100).clamp(0, 999) : 0;
}

final statisticsServiceProvider = FutureProvider<StatisticsService>((ref) async {
  final dao = await ref.watch(transactionDaoProvider.future);
  return StatisticsService(dao);
});

final homeStatisticsProvider = FutureProvider<HomeStatistics>((ref) async {
  ref.watch(transactionRefreshProvider);
  final bookId = ref.watch(activeBookIdProvider);
  if (bookId == null) {
    return const HomeStatistics(
      today: PeriodSummary(expenseCents: 0, incomeCents: 0),
      week: PeriodSummary(expenseCents: 0, incomeCents: 0),
      month: PeriodSummary(expenseCents: 0, incomeCents: 0),
      year: PeriodSummary(expenseCents: 0, incomeCents: 0),
      monthTrend: [],
      yearlyTrend: [],
    );
  }

  final service = await ref.watch(statisticsServiceProvider.future);
  return service.getHomeStatistics(
    bookId,
    weekStartsOn: ref.watch(weekStartsOnProvider),
    monthStartDay: ref.watch(monthStartDayProvider),
  );
});

final statisticsFullReportProvider =
    FutureProvider<StatisticsFullReport>((ref) async {
  ref.watch(transactionRefreshProvider);
  final filter = ref.watch(statisticsFilterProvider);
  final range = filter.resolveRange(
    weekStartsOn: ref.watch(weekStartsOnProvider),
    monthStartDay: ref.watch(monthStartDayProvider),
  );

  final categories = await ref.watch(allCategoriesProvider.future);
  final accounts = await ref.watch(statisticsAccountsProvider.future);
  final categoryNames = _buildCategoryNameMap(categories);
  final categorySortOrders = {
    for (final category in categories)
      if (category.id != null) category.id!: category.sortOrder,
  };
  final accountNames = {
    for (final account in accounts)
      if (account.id != null) account.id!: account.name,
  };
  final accountSortOrders = {
    for (final account in accounts)
      if (account.id != null) account.id!: account.sortOrder,
  };

  final service = await ref.watch(statisticsServiceProvider.future);
  final keyword = filter.keyword.trim().isEmpty ? null : filter.keyword.trim();

  return service.getFullReport(
    query: StatisticsQueryParams(
      bookId: filter.bookId,
      start: range.start,
      end: range.end,
      type: filter.transactionType,
      keyword: keyword,
      accountId: filter.accountId,
    ),
    categoryNames: categoryNames,
    categorySortOrders: categorySortOrders,
    accountNames: accountNames,
    accountSortOrders: accountSortOrders,
    accounts: accounts,
  );
});

/// 兼容旧引用
final statisticsOverviewProvider = statisticsFullReportProvider;

final statisticsBudgetKpiProvider =
    FutureProvider<BudgetKpiSummary?>((ref) async {
  ref.watch(transactionRefreshProvider);
  final filter = ref.watch(statisticsFilterProvider);
  final bookId = filter.bookId ?? ref.watch(activeBookIdProvider);
  if (bookId == null) return null;

  final categories = await ref.watch(allCategoriesProvider.future);
  final categoryNames = _buildCategoryNameMap(categories);
  final budgetService = await ref.watch(budgetServiceProvider.future);
  final monthStartDay = ref.watch(monthStartDayProvider);
  final budgets = await budgetService.getBudgetsWithProgress(
    bookId: bookId,
    categoryNames: categoryNames,
    monthStartDay: monthStartDay,
  );
  if (budgets.isEmpty) return null;

  final primary = budgets.firstWhere(
    (item) => item.budget.categoryId == null,
    orElse: () => budgets.first,
  );

  return BudgetKpiSummary(
    label: primary.categoryName,
    spentCents: primary.spentCents,
    budgetCents: primary.budget.amount,
    isOverBudget: primary.isOverBudget,
  );
});

final statisticsAccountsProvider = FutureProvider<List<Account>>((ref) async {
  ref.watch(transactionRefreshProvider);
  final filter = ref.watch(statisticsFilterProvider);
  final dao = await ref.watch(accountDaoProvider.future);
  return dao.getAll(bookId: filter.bookId);
});

final statisticsAssetTrendProvider =
    FutureProvider<List<MonthlyValuePoint>>((ref) async {
  ref.watch(transactionRefreshProvider);
  final assetMetric = ref.watch(
    statisticsPageProvider.select((s) => s.assetMetric),
  );
  final focusYear = ref.watch(
    statisticsPageProvider.select((s) => s.focusYear),
  );
  final filter = ref.watch(statisticsFilterProvider);
  final bookId = filter.bookId;

  final accounts = await ref.watch(statisticsAccountsProvider.future);
  final summary = AssetSummary.fromAccounts(accounts);
  final service = await ref.watch(statisticsServiceProvider.future);
  final year = focusYear ?? DateTime.now().year;

  final netAssets = switch (assetMetric) {
    StatisticsAssetMetric.totalAssets => summary.totalAssetsCents,
    StatisticsAssetMetric.totalLiabilities => summary.totalLiabilitiesCents,
    StatisticsAssetMetric.netAssets => summary.netAssetsCents,
  };

  return service.getMonthlyAssetTrend(
    bookId: bookId,
    year: year,
    currentNetAssetsCents: netAssets,
    metric: assetMetric,
  );
});

final statisticsCategoryTrendProvider =
    FutureProvider<List<MonthlyTrendPoint>>((ref) async {
  ref.watch(transactionRefreshProvider);
  final selectedCategoryId = ref.watch(
    statisticsPageProvider.select((s) => s.selectedCategoryId),
  );
  final filter = ref.watch(statisticsFilterProvider);
  final bookId = filter.bookId;

  final report = ref.watch(statisticsFullReportProvider).valueOrNull;
  final categoryId = selectedCategoryId ??
      (report?.expenseByCategory.isNotEmpty == true
          ? report!.expenseByCategory.first.categoryId
          : null);
  if (categoryId == null) return const [];

  final service = await ref.watch(statisticsServiceProvider.future);
  final year = DateTime.now().year;
  final keyword =
      filter.keyword.trim().isEmpty ? null : filter.keyword.trim();

  return service.getCategoryMonthlyTrend(
    bookId: bookId,
    categoryId: categoryId,
    year: year,
    keyword: keyword,
  );
});

Map<int, String> _buildCategoryNameMap(List<Category> categories) {
  final byId = {
    for (final category in categories)
      if (category.id != null) category.id!: category,
  };

  return {
    for (final entry in byId.entries)
      entry.key: _resolveCategoryName(entry.value, byId),
  };
}

String _resolveCategoryName(Category category, Map<int, Category> byId) {
  final parentId = category.parentId;
  if (parentId != null && byId.containsKey(parentId)) {
    return '${byId[parentId]!.name} > ${category.name}';
  }
  return category.name;
}
