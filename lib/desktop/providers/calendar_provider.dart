import 'package:ezbookkeeping_desktop/core/services/statistics_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/statistics_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 与交易筛选月份同步，供日历视图使用。
final calendarMonthProvider = Provider<DateTime>((ref) {
  return ref.watch(transactionFilterProvider.select((s) => s.selectedMonth));
});

final calendarSelectedDayProvider = StateProvider<DateTime?>((ref) => null);

final calendarMonthDataProvider =
    FutureProvider<List<DailyTrendPoint>>((ref) async {
  ref.watch(transactionRefreshProvider);
  final bookId = ref.watch(activeBookIdProvider);
  final month = ref.watch(calendarMonthProvider);
  if (bookId == null) return [];

  final service = await ref.watch(statisticsServiceProvider.future);
  return service.getDailyTrend(
    bookId,
    AppDateUtils.startOfMonth(month),
    AppDateUtils.endOfMonth(month),
  );
});

final calendarDayTransactionsProvider =
    FutureProvider.family<int, DateTime>((ref, day) async {
  ref.watch(transactionRefreshProvider);
  final bookId = ref.watch(activeBookIdProvider);
  if (bookId == null) return 0;

  final dao = await ref.watch(transactionDaoProvider.future);
  return dao.count(
    bookId: bookId,
    startDate: AppDateUtils.startOfDay(day),
    endDate: AppDateUtils.endOfDay(day),
  );
});
