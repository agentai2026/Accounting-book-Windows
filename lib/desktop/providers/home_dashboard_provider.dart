import 'package:ezbookkeeping_desktop/core/constants/bookkeeping_metrics_rules.dart';
import 'package:ezbookkeeping_desktop/core/models/book.dart';
import 'package:ezbookkeeping_desktop/core/services/budget_service.dart';
import 'package:ezbookkeeping_desktop/core/services/statistics_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/account_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/loan_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/statistics_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/home/home_dashboard_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeDashboardData {
  const HomeDashboardData({
    required this.stats,
    required this.monthOverview,
    required this.recentTransactions,
    required this.assetSummary,
    required this.activeBook,
    required this.budgets,
    required this.monthTransactionCount,
  });

  final HomeStatistics stats;
  final StatisticsOverview monthOverview;
  final List<TransactionRowData> recentTransactions;
  final AssetSummary assetSummary;
  final Book? activeBook;
  final List<BudgetWithProgress> budgets;
  final int monthTransactionCount;

  factory HomeDashboardData.empty() {
    return HomeDashboardData(
      stats: const HomeStatistics(
        today: PeriodSummary(expenseCents: 0, incomeCents: 0),
        week: PeriodSummary(expenseCents: 0, incomeCents: 0),
        month: PeriodSummary(expenseCents: 0, incomeCents: 0),
        year: PeriodSummary(expenseCents: 0, incomeCents: 0),
        monthTrend: [],
        yearlyTrend: [],
      ),
      monthOverview: StatisticsOverview(
        summary: const PeriodSummary(expenseCents: 0, incomeCents: 0),
        trend: const [],
        expenseByCategory: const [],
        incomeByCategory: const [],
        start: DateTime(2000),
        end: DateTime(2000),
      ),
      recentTransactions: const [],
      assetSummary: const AssetSummary(
        totalAssetsCents: 0,
        totalLiabilitiesCents: 0,
        netAssetsCents: 0,
        accountCount: 0,
      ),
      activeBook: null,
      budgets: const [],
      monthTransactionCount: 0,
    );
  }

  double? get monthSavingsRate => BookkeepingMetricsRules.calcSavingsRate(
        incomeCents: monthOverview.summary.incomeCents,
        netCents: monthOverview.summary.netCents,
      );
}

final homeDashboardProvider = FutureProvider<HomeDashboardData>((ref) async {
  ref.watch(transactionRefreshProvider);
  ref.watch(budgetRefreshProvider);

  final bookId = ref.watch(activeBookIdProvider);
  if (bookId == null) {
    return HomeDashboardData.empty();
  }

  final now = DateTime.now();
  final weekStartsOn = ref.watch(weekStartsOnProvider);
  final monthStartDay = ref.watch(monthStartDayProvider);
  final monthStart = AppDateUtils.startOfBillingMonth(
    now,
    monthStartDay: monthStartDay,
  );
  final monthEnd = AppDateUtils.endOfBillingMonth(
    now,
    monthStartDay: monthStartDay,
  );

  final statsService = await ref.watch(statisticsServiceProvider.future);
  final bookkeeping = await ref.watch(bookkeepingServiceProvider.future);
  final categories = await ref.watch(allCategoriesProvider.future);
  final accounts = await ref.watch(accountListProvider.future);
  final activeBook = await ref.watch(activeBookProvider.future);
  final budgets = await ref.watch(budgetProgressListProvider.future);

  final categoryNames = {
    for (final category in categories)
      if (category.id != null) category.id!: category.name,
  };
  final categorySortOrders = {
    for (final category in categories)
      if (category.id != null) category.id!: category.sortOrder,
  };

  final stats = await statsService.getHomeStatistics(
    bookId,
    weekStartsOn: weekStartsOn,
    monthStartDay: monthStartDay,
  );
  final monthOverview = await statsService.getOverview(
    bookId: bookId,
    start: monthStart,
    end: monthEnd,
    categoryNames: categoryNames,
    categorySortOrders: categorySortOrders,
  );

  final recentResult = await bookkeeping.getTransactions(
    bookId: bookId,
    limit: 8,
    offset: 0,
  );
  final recentTransactions = await recentResult.when(
    success: (list) => buildTransactionRowData(ref, list),
    failure: (error) => throw error,
  );

  final countResult = await bookkeeping.getTransactionCount(
    bookId: bookId,
    startDate: monthStart,
    endDate: monthEnd,
  );
  final monthTransactionCount = countResult.when(
    success: (count) => count,
    failure: (error) => throw error,
  );

  return HomeDashboardData(
    stats: stats,
    monthOverview: monthOverview,
    recentTransactions: recentTransactions,
    assetSummary: AssetSummary.fromAccounts(accounts),
    activeBook: activeBook,
    budgets: budgets,
    monthTransactionCount: monthTransactionCount,
  );
});

enum HomePeriodScope { today, week, month, year }

void applyHomePeriodFilter(WidgetRef ref, HomePeriodScope scope) {
  final now = DateTime.now();
  final notifier = ref.read(transactionFilterProvider.notifier);
  final weekStartsOn = ref.read(weekStartsOnProvider);
  final monthStartDay = ref.read(monthStartDayProvider);

  switch (scope) {
    case HomePeriodScope.today:
      notifier.setCustomRange(
        AppDateUtils.startOfDay(now),
        AppDateUtils.endOfDay(now),
      );
    case HomePeriodScope.week:
      notifier.setCustomRange(
        AppDateUtils.startOfWeek(now, weekStartsOn: weekStartsOn),
        AppDateUtils.endOfWeek(now, weekStartsOn: weekStartsOn),
      );
    case HomePeriodScope.month:
      notifier.setCustomRange(
        AppDateUtils.startOfBillingMonth(now, monthStartDay: monthStartDay),
        AppDateUtils.endOfBillingMonth(now, monthStartDay: monthStartDay),
      );
    case HomePeriodScope.year:
      notifier.setCustomRange(
        AppDateUtils.startOfYear(now),
        AppDateUtils.endOfYear(now),
      );
  }
}

void refreshHomeDashboard(WidgetRef ref) {
  ref.invalidate(homeDashboardProvider);
  ref.invalidate(homeStatisticsProvider);
  ref.read(transactionRefreshProvider.notifier).state++;
}
