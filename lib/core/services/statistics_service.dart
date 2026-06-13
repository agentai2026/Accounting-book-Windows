import 'package:ezbookkeeping_desktop/core/constants/bookkeeping_metrics_rules.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/transaction_dao.dart';
import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/statistics_query.dart';
import 'package:ezbookkeeping_desktop/core/services/income_expense_totals_calculator.dart';
import 'package:ezbookkeeping_desktop/core/services/transfer_metrics_calculator.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';

class PeriodSummary {
  const PeriodSummary({
    required this.expenseCents,
    required this.incomeCents,
  });

  final int expenseCents;
  final int incomeCents;

  int get netCents => incomeCents - expenseCents;
}

class DailyTrendPoint {
  const DailyTrendPoint({
    required this.date,
    required this.expenseCents,
    required this.incomeCents,
  });

  final DateTime date;
  final int expenseCents;
  final int incomeCents;
}

class MonthlyTrendPoint {
  const MonthlyTrendPoint({
    required this.month,
    required this.expenseCents,
    required this.incomeCents,
  });

  final DateTime month;
  final int expenseCents;
  final int incomeCents;
}

class HomeStatistics {
  const HomeStatistics({
    required this.today,
    required this.week,
    required this.month,
    required this.year,
    required this.monthTrend,
    required this.yearlyTrend,
  });

  final PeriodSummary today;
  final PeriodSummary week;
  final PeriodSummary month;
  final PeriodSummary year;
  final List<DailyTrendPoint> monthTrend;
  final List<MonthlyTrendPoint> yearlyTrend;
}

class CategoryBreakdownItem {
  const CategoryBreakdownItem({
    required this.categoryId,
    required this.categoryName,
    required this.amountCents,
    required this.percentage,
    this.sortOrder = 0,
  });

  final int categoryId;
  final String categoryName;
  final int amountCents;
  final double percentage;
  final int sortOrder;
}

class AccountBreakdownItem {
  const AccountBreakdownItem({
    required this.accountId,
    required this.accountName,
    required this.amountCents,
    required this.percentage,
    required this.sortOrder,
  });

  final int accountId;
  final String accountName;
  final int amountCents;
  final double percentage;
  final int sortOrder;
}

class MonthlyValuePoint {
  const MonthlyValuePoint({
    required this.month,
    required this.valueCents,
  });

  final DateTime month;
  final int valueCents;
}

enum StatisticsAssetMetric { totalAssets, totalLiabilities, netAssets }

class AccountFlowItem {
  const AccountFlowItem({
    required this.accountId,
    required this.accountName,
    required this.amountCents,
    required this.percentage,
    required this.sortOrder,
  });

  final int accountId;
  final String accountName;
  final int amountCents;
  final double percentage;
  final int sortOrder;
}

class StatisticsFullReport {
  const StatisticsFullReport({
    required this.summary,
    required this.previousSummary,
    required this.transactionCount,
    required this.transferCount,
    required this.transferAmountCents,
    required this.reimbursableCount,
    required this.reimbursableCents,
    required this.dailyTrend,
    required this.monthlyTrend,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.expenseByAccount,
    required this.incomeByAccount,
    required this.accountBalances,
    required this.start,
    required this.end,
    required this.previousStart,
    required this.previousEnd,
    this.activeDayCount,
  });

  final PeriodSummary summary;
  final PeriodSummary previousSummary;
  final int transactionCount;
  final int transferCount;
  final int transferAmountCents;
  final int reimbursableCount;
  final int reimbursableCents;
  final List<DailyTrendPoint> dailyTrend;
  final List<MonthlyTrendPoint> monthlyTrend;
  final List<CategoryBreakdownItem> expenseByCategory;
  final List<CategoryBreakdownItem> incomeByCategory;
  final List<AccountFlowItem> expenseByAccount;
  final List<AccountFlowItem> incomeByAccount;
  final List<AccountBreakdownItem> accountBalances;
  final DateTime start;
  final DateTime end;
  final DateTime previousStart;
  final DateTime previousEnd;

  /// 有账单时的实际天数（用于日均支出）；为空则回退到筛选区间
  final int? activeDayCount;

  double? get savingsRate => BookkeepingMetricsRules.calcSavingsRate(
        incomeCents: summary.incomeCents,
        netCents: summary.netCents,
      );

  int get dayCount => BookkeepingMetricsRules.calcDaySpan(start, end);

  int get effectiveDayCount => activeDayCount ?? dayCount;

  int get avgDailyExpenseCents =>
      summary.expenseCents ~/ (effectiveDayCount > 0 ? effectiveDayCount : 1);

  bool get supportsDailyTrend =>
      StatisticsService.supportsDailyTrend(start, end);

  double? get expenseChangePercent {
    if (previousSummary.expenseCents == 0) return null;
    return (summary.expenseCents - previousSummary.expenseCents) /
        previousSummary.expenseCents *
        100;
  }

  double? get incomeChangePercent {
    if (previousSummary.incomeCents == 0) return null;
    return (summary.incomeCents - previousSummary.incomeCents) /
        previousSummary.incomeCents *
        100;
  }
}

class StatisticsOverview {
  const StatisticsOverview({
    required this.summary,
    required this.trend,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.start,
    required this.end,
  });

  final PeriodSummary summary;
  final List<DailyTrendPoint> trend;
  final List<CategoryBreakdownItem> expenseByCategory;
  final List<CategoryBreakdownItem> incomeByCategory;
  final DateTime start;
  final DateTime end;
}

class StatisticsService {
  StatisticsService(this._transactionDao);

  /// Daily charts skip beyond this many days to avoid thousands of DB rows / chart points.
  static const kMaxDailyTrendDays = 92;

  final TransactionDao _transactionDao;

  static bool supportsDailyTrend(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1 <= kMaxDailyTrendDays;
  }

  Future<HomeStatistics> getHomeStatistics(
    int bookId, {
    DateTime? now,
    int weekStartsOn = DateTime.monday,
    int monthStartDay = 1,
  }) async {
    final reference = now ?? DateTime.now();

    final today = await getPeriodSummary(
      bookId,
      AppDateUtils.startOfDay(reference),
      AppDateUtils.endOfDay(reference),
    );
    final week = await getPeriodSummary(
      bookId,
      AppDateUtils.startOfWeek(reference, weekStartsOn: weekStartsOn),
      AppDateUtils.endOfWeek(reference, weekStartsOn: weekStartsOn),
    );
    final month = await getPeriodSummary(
      bookId,
      AppDateUtils.startOfBillingMonth(reference, monthStartDay: monthStartDay),
      AppDateUtils.endOfBillingMonth(reference, monthStartDay: monthStartDay),
    );
    final year = await getPeriodSummary(
      bookId,
      AppDateUtils.startOfYear(reference),
      AppDateUtils.endOfYear(reference),
    );
    final monthTrend = await getDailyTrend(
      bookId,
      AppDateUtils.startOfBillingMonth(reference, monthStartDay: monthStartDay),
      AppDateUtils.endOfDay(reference),
    );
    final yearlyTrend = await getMonthlyTrend(bookId, reference: reference);

    return HomeStatistics(
      today: today,
      week: week,
      month: month,
      year: year,
      monthTrend: monthTrend,
      yearlyTrend: yearlyTrend,
    );
  }

  Future<List<MonthlyTrendPoint>> getMonthlyTrend(
    int bookId, {
    DateTime? reference,
  }) async {
    final now = reference ?? DateTime.now();
    final end = AppDateUtils.endOfMonth(now);
    final start = DateTime(now.year, now.month - 11);

    final expenseByMonth = await _transactionDao.sumAmountGroupByMonth(
      bookId: bookId,
      type: TransactionType.expense,
      start: AppDateUtils.startOfMonth(start),
      end: end,
    );
    final incomeByMonth = await _transactionDao.sumAmountGroupByMonth(
      bookId: bookId,
      type: TransactionType.income,
      start: AppDateUtils.startOfMonth(start),
      end: end,
    );

    final points = <MonthlyTrendPoint>[];
    for (var i = 0; i < 12; i++) {
      final month = DateTime(start.year, start.month + i);
      final key =
          '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
      points.add(
        MonthlyTrendPoint(
          month: month,
          expenseCents: expenseByMonth[key] ?? 0,
          incomeCents: incomeByMonth[key] ?? 0,
        ),
      );
    }

    return points;
  }

  Future<PeriodSummary> getPeriodSummary(
    int bookId,
    DateTime start,
    DateTime end,
  ) async {
    final expense = await _transactionDao.sumAmountByType(
      bookId: bookId,
      type: TransactionType.expense,
      start: start,
      end: end,
    );
    final income = await _transactionDao.sumAmountByType(
      bookId: bookId,
      type: TransactionType.income,
      start: start,
      end: end,
    );
    return PeriodSummary(expenseCents: expense, incomeCents: income);
  }

  Future<List<DailyTrendPoint>> getDailyTrend(
    int bookId,
    DateTime start,
    DateTime end,
  ) async {
    final expenseByDay = await _transactionDao.sumAmountGroupByDay(
      bookId: bookId,
      type: TransactionType.expense,
      start: start,
      end: end,
    );
    final incomeByDay = await _transactionDao.sumAmountGroupByDay(
      bookId: bookId,
      type: TransactionType.income,
      start: start,
      end: end,
    );

    final points = <DailyTrendPoint>[];
    var cursor = AppDateUtils.startOfDay(start);
    final lastDay = AppDateUtils.startOfDay(end);

    while (!cursor.isAfter(lastDay)) {
      final key =
          '${cursor.year.toString().padLeft(4, '0')}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}';
      points.add(
        DailyTrendPoint(
          date: cursor,
          expenseCents: expenseByDay[key] ?? 0,
          incomeCents: incomeByDay[key] ?? 0,
        ),
      );
      cursor = cursor.add(const Duration(days: 1));
    }

    return points;
  }

  Future<StatisticsOverview> getOverview({
    required int bookId,
    required DateTime start,
    required DateTime end,
    required Map<int, String> categoryNames,
    Map<int, int>? categorySortOrders,
  }) async {
    final summary = await getPeriodSummary(bookId, start, end);
    final trend = await getDailyTrend(bookId, start, end);
    final expenseByCategory = await _getCategoryBreakdown(
      bookId: bookId,
      type: TransactionType.expense,
      start: start,
      end: end,
      categoryNames: categoryNames,
      categorySortOrders: categorySortOrders,
    );
    final incomeByCategory = await _getCategoryBreakdown(
      bookId: bookId,
      type: TransactionType.income,
      start: start,
      end: end,
      categoryNames: categoryNames,
      categorySortOrders: categorySortOrders,
    );

    return StatisticsOverview(
      summary: summary,
      trend: trend,
      expenseByCategory: expenseByCategory,
      incomeByCategory: incomeByCategory,
      start: start,
      end: end,
    );
  }

  Future<List<CategoryBreakdownItem>> _getCategoryBreakdown({
    required int bookId,
    required TransactionType type,
    required DateTime start,
    required DateTime end,
    required Map<int, String> categoryNames,
    Map<int, int>? categorySortOrders,
  }) async {
    final grouped = await _transactionDao.sumAmountGroupByCategory(
      bookId: bookId,
      type: type,
      start: start,
      end: end,
    );

    if (grouped.isEmpty) return [];

    final total = grouped.values.fold<int>(0, (sum, amount) => sum + amount);
    final items = grouped.entries
        .map(
          (entry) => CategoryBreakdownItem(
            categoryId: entry.key,
            categoryName: categoryNames[entry.key] ?? '未知分类',
            amountCents: entry.value,
            percentage: total > 0 ? entry.value / total * 100 : 0,
            sortOrder: categorySortOrders?[entry.key] ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) => b.amountCents.compareTo(a.amountCents));

    return items;
  }

  Future<StatisticsFullReport> getFullReport({
    required StatisticsQueryParams query,
    required Map<int, String> categoryNames,
    Map<int, int>? categorySortOrders,
    required Map<int, String> accountNames,
    required Map<int, int> accountSortOrders,
    required List<Account> accounts,
  }) async {
    final previous = _previousPeriod(query.start, query.end);
    final previousQuery = StatisticsQueryParams(
      bookId: query.bookId,
      start: previous.start,
      end: previous.end,
      type: query.type,
      keyword: query.keyword,
      accountId: query.accountId,
    );
    final transferQuery = StatisticsQueryParams(
      bookId: query.bookId,
      start: query.start,
      end: query.end,
      type: TransactionType.transfer,
      keyword: query.keyword,
      accountId: query.accountId,
    );
    final fetchDailyTrend = supportsDailyTrend(query.start, query.end);

    final transactionCountFuture = _transactionDao.countStatistics(query);
    final transferCountFuture = _transactionDao.countStatistics(transferQuery);
    final transferBriefFuture = _transactionDao.listStatisticsBrief(query);
    final prevBriefFuture = _transactionDao.listStatisticsBrief(previousQuery);
    final dateBoundsFuture = _transactionDao.getStatisticsDateBounds(query);
    final dailyTrendFuture = fetchDailyTrend
        ? _getFilteredDailyTrend(query)
        : Future<List<DailyTrendPoint>>.value(const []);
    final monthlyTrendFuture = _getFilteredMonthlyTrend(query);
    final expenseByCategoryFuture = _getCategoryBreakdownFiltered(
      query: query,
      type: TransactionType.expense,
      categoryNames: categoryNames,
      categorySortOrders: categorySortOrders,
    );
    final incomeByCategoryFuture = _getCategoryBreakdownFiltered(
      query: query,
      type: TransactionType.income,
      categoryNames: categoryNames,
      categorySortOrders: categorySortOrders,
    );
    final expenseByAccountFuture = _getAccountFlowBreakdown(
      query: query,
      type: TransactionType.expense,
      accountNames: accountNames,
      accountSortOrders: accountSortOrders,
    );
    final incomeByAccountFuture = _getAccountFlowBreakdown(
      query: query,
      type: TransactionType.income,
      accountNames: accountNames,
      accountSortOrders: accountSortOrders,
    );
    final reimbursableFuture =
        _transactionDao.sumReimbursableStatistics(query);

    final results = await Future.wait([
      transactionCountFuture,
      transferCountFuture,
      transferBriefFuture,
      prevBriefFuture,
      dateBoundsFuture,
      dailyTrendFuture,
      monthlyTrendFuture,
      expenseByCategoryFuture,
      incomeByCategoryFuture,
      expenseByAccountFuture,
      incomeByAccountFuture,
      reimbursableFuture,
    ]);

    final transactionCount = results[0] as int;
    final transferCount = results[1] as int;
    final transferBriefRows = results[2] as List<({int type, int amount, String? comment})>;
    final prevBriefRows = results[3] as List<({int type, int amount, String? comment})>;
    final dateBounds = results[4] as ({DateTime? min, DateTime? max});
    final dailyTrend = results[5] as List<DailyTrendPoint>;
    final monthlyTrend = results[6] as List<MonthlyTrendPoint>;
    final expenseByCategory = results[7] as List<CategoryBreakdownItem>;
    final incomeByCategory = results[8] as List<CategoryBreakdownItem>;
    final expenseByAccount = results[9] as List<AccountFlowItem>;
    final incomeByAccount = results[10] as List<AccountFlowItem>;
    final reimbursable = results[11] as ({int count, int amountCents});

    StatisticsBriefRow mapBrief(({int type, int amount, String? comment}) row) {
      return StatisticsBriefRow(
        type: TransactionType.fromValue(row.type),
        amount: row.amount,
        comment: row.comment,
      );
    }

    final briefRows = transferBriefRows.map(mapBrief).toList();
    final prevRows = prevBriefRows.map(mapBrief).toList();

    final totals = IncomeExpenseTotalsCalculator.calculate(briefRows);
    final prevTotals = IncomeExpenseTotalsCalculator.calculate(prevRows);
    final summary = PeriodSummary(
      expenseCents: totals.expenseCents,
      incomeCents: totals.incomeCents,
    );
    final previousSummary = PeriodSummary(
      expenseCents: prevTotals.expenseCents,
      incomeCents: prevTotals.incomeCents,
    );

    final transferMetrics = TransferMetricsCalculator.calculate(
      rows: briefRows,
      mode: TransferMetricMode.netTransfer,
    );

    int? activeDayCount;
    if (dateBounds.min != null && dateBounds.max != null) {
      activeDayCount = BookkeepingMetricsRules.calcDaySpan(
        dateBounds.min!,
        dateBounds.max!,
      );
    }

    return StatisticsFullReport(
      summary: summary,
      previousSummary: previousSummary,
      transactionCount: transactionCount,
      transferCount: transferCount,
      transferAmountCents: transferMetrics.amountCents.abs(),
      reimbursableCount: reimbursable.count,
      reimbursableCents: reimbursable.amountCents,
      activeDayCount: activeDayCount,
      dailyTrend: dailyTrend,
      monthlyTrend: monthlyTrend,
      expenseByCategory: expenseByCategory,
      incomeByCategory: incomeByCategory,
      expenseByAccount: expenseByAccount,
      incomeByAccount: incomeByAccount,
      accountBalances: buildAccountBreakdown(accounts),
      start: query.start,
      end: query.end,
      previousStart: previous.start,
      previousEnd: previous.end,
    );
  }

  ({DateTime start, DateTime end}) _previousPeriod(
    DateTime start,
    DateTime end,
  ) {
    final duration = end.difference(start);
    final previousEnd = AppDateUtils.endOfDay(
      start.subtract(const Duration(days: 1)),
    );
    final previousStart = AppDateUtils.startOfDay(
      previousEnd.subtract(duration),
    );
    return (start: previousStart, end: previousEnd);
  }

  Future<List<DailyTrendPoint>> _getFilteredDailyTrend(
    StatisticsQueryParams query,
  ) async {
    final expenseByDay = await _transactionDao.sumAmountGroupByDayFiltered(
      query,
      type: TransactionType.expense,
    );
    final incomeByDay = await _transactionDao.sumAmountGroupByDayFiltered(
      query,
      type: TransactionType.income,
    );

    final points = <DailyTrendPoint>[];
    var cursor = AppDateUtils.startOfDay(query.start);
    final lastDay = AppDateUtils.startOfDay(query.end);

    while (!cursor.isAfter(lastDay)) {
      final key =
          '${cursor.year.toString().padLeft(4, '0')}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}';
      points.add(
        DailyTrendPoint(
          date: cursor,
          expenseCents: expenseByDay[key] ?? 0,
          incomeCents: incomeByDay[key] ?? 0,
        ),
      );
      cursor = cursor.add(const Duration(days: 1));
    }
    return points;
  }

  Future<List<MonthlyTrendPoint>> _getFilteredMonthlyTrend(
    StatisticsQueryParams query,
  ) async {
    final expenseByMonth = await _transactionDao.sumAmountGroupByMonthFiltered(
      query,
      type: TransactionType.expense,
    );
    final incomeByMonth = await _transactionDao.sumAmountGroupByMonthFiltered(
      query,
      type: TransactionType.income,
    );

    final months = <DateTime>[];
    var cursor = DateTime(query.start.year, query.start.month);
    final endMonth = DateTime(query.end.year, query.end.month);
    while (!cursor.isAfter(endMonth)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    return months
        .map(
          (month) {
            final key =
                '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
            return MonthlyTrendPoint(
              month: month,
              expenseCents: expenseByMonth[key] ?? 0,
              incomeCents: incomeByMonth[key] ?? 0,
            );
          },
        )
        .toList();
  }

  Future<List<CategoryBreakdownItem>> _getCategoryBreakdownFiltered({
    required StatisticsQueryParams query,
    required TransactionType type,
    required Map<int, String> categoryNames,
    Map<int, int>? categorySortOrders,
  }) async {
    final grouped = await _transactionDao.sumAmountGroupByCategoryFiltered(
      query,
      type: type,
    );
    if (grouped.isEmpty) return [];

    final total = grouped.values.fold<int>(0, (sum, amount) => sum + amount);
    return grouped.entries
        .map(
          (entry) => CategoryBreakdownItem(
            categoryId: entry.key,
            categoryName: categoryNames[entry.key] ?? '未知分类',
            amountCents: entry.value,
            percentage: total > 0 ? entry.value / total * 100 : 0,
            sortOrder: categorySortOrders?[entry.key] ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) => b.amountCents.compareTo(a.amountCents));
  }

  Future<List<AccountFlowItem>> _getAccountFlowBreakdown({
    required StatisticsQueryParams query,
    required TransactionType type,
    required Map<int, String> accountNames,
    required Map<int, int> accountSortOrders,
  }) async {
    final grouped = await _transactionDao.sumAmountGroupByAccountFiltered(
      query,
      type: type,
    );
    if (grouped.isEmpty) return [];

    final total = grouped.values.fold<int>(0, (sum, amount) => sum + amount);
    return grouped.entries
        .map(
          (entry) => AccountFlowItem(
            accountId: entry.key,
            accountName: accountNames[entry.key] ?? '未知账户',
            amountCents: entry.value,
            percentage: total > 0 ? entry.value / total * 100 : 0,
            sortOrder: accountSortOrders[entry.key] ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) => b.amountCents.compareTo(a.amountCents));
  }

  List<AccountBreakdownItem> buildAccountBreakdown(List<Account> accounts) {
    final visible = accounts.where((a) => a.id != null).toList();
    if (visible.isEmpty) return [];

    final total = visible.fold<int>(
      0,
      (sum, a) => sum + a.balance.abs(),
    );
    return visible
        .map(
          (account) => AccountBreakdownItem(
            accountId: account.id!,
            accountName: account.name,
            amountCents: account.balance.abs(),
            percentage: total > 0 ? account.balance.abs() / total * 100 : 0,
            sortOrder: account.sortOrder,
          ),
        )
        .toList();
  }

  Future<List<MonthlyValuePoint>> getMonthlyAssetTrend({
    int? bookId,
    required int year,
    required int currentNetAssetsCents,
    StatisticsAssetMetric metric = StatisticsAssetMetric.netAssets,
  }) async {
    if (metric != StatisticsAssetMetric.netAssets) {
      return _getMonthlyFlowTrend(bookId: bookId, year: year, metric: metric);
    }

    final start = DateTime(year, 1, 1);
    final end = AppDateUtils.endOfMonth(DateTime(year, 12));
    final expenseByMonth = await _transactionDao.sumAmountGroupByMonth(
      bookId: bookId,
      type: TransactionType.expense,
      start: start,
      end: end,
    );
    final incomeByMonth = await _transactionDao.sumAmountGroupByMonth(
      bookId: bookId,
      type: TransactionType.income,
      start: start,
      end: end,
    );

    final monthlyNet = List<int>.generate(12, (index) {
      final month = DateTime(year, index + 1);
      final key =
          '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
      return (incomeByMonth[key] ?? 0) - (expenseByMonth[key] ?? 0);
    });

    var cumulative = 0;
    final cumulatives = <int>[];
    for (final net in monthlyNet) {
      cumulative += net;
      cumulatives.add(cumulative);
    }

    final yearEndCumulative = cumulatives.isEmpty ? 0 : cumulatives.last;
    return List.generate(12, (index) {
      final remaining = yearEndCumulative - cumulatives[index];
      return MonthlyValuePoint(
        month: DateTime(year, index + 1),
        valueCents: currentNetAssetsCents - remaining,
      );
    });
  }

  Future<List<MonthlyValuePoint>> _getMonthlyFlowTrend({
    int? bookId,
    required int year,
    required StatisticsAssetMetric metric,
  }) async {
    final start = DateTime(year, 1, 1);
    final end = AppDateUtils.endOfMonth(DateTime(year, 12));
    final type = metric == StatisticsAssetMetric.totalLiabilities
        ? TransactionType.expense
        : TransactionType.income;

    final grouped = await _transactionDao.sumAmountGroupByMonth(
      bookId: bookId,
      type: type,
      start: start,
      end: end,
    );

    return List.generate(12, (index) {
      final month = DateTime(year, index + 1);
      final key =
          '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
      return MonthlyValuePoint(
        month: month,
        valueCents: grouped[key] ?? 0,
      );
    });
  }

  Future<List<MonthlyTrendPoint>> getCategoryMonthlyTrend({
    int? bookId,
    required int categoryId,
    required int year,
    String? keyword,
  }) async {
    final start = DateTime(year, 1, 1);
    final end = AppDateUtils.endOfMonth(DateTime(year, 12));
    final grouped = await _transactionDao.sumAmountGroupByMonthForCategory(
      bookId: bookId,
      categoryId: categoryId,
      start: start,
      end: end,
      keyword: keyword,
    );

    return List.generate(12, (index) {
      final month = DateTime(year, index + 1);
      final key =
          '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
      return MonthlyTrendPoint(
        month: month,
        expenseCents: grouped[key] ?? 0,
        incomeCents: 0,
      );
    });
  }
}
