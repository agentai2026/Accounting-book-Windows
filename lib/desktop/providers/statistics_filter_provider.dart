import 'dart:async';

import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StatisticsPeriod { today, week, month, quarter, year, all, custom }

class StatisticsFilter {
  const StatisticsFilter({
    this.period = StatisticsPeriod.month,
    this.customStart,
    this.customEnd,
    this.transactionType,
    this.accountId,
    this.bookId,
    this.keyword = '',
  });

  final StatisticsPeriod period;
  final DateTime? customStart;
  final DateTime? customEnd;
  final TransactionType? transactionType;
  final int? accountId;
  /// 为 null 时表示全部账本
  final int? bookId;
  final String keyword;

  StatisticsFilter copyWith({
    StatisticsPeriod? period,
    DateTime? customStart,
    DateTime? customEnd,
    TransactionType? transactionType,
    bool clearTransactionType = false,
    int? accountId,
    bool clearAccountId = false,
    int? bookId,
    bool clearBookId = false,
    String? keyword,
  }) {
    return StatisticsFilter(
      period: period ?? this.period,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      transactionType:
          clearTransactionType ? null : (transactionType ?? this.transactionType),
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      bookId: clearBookId ? null : (bookId ?? this.bookId),
      keyword: keyword ?? this.keyword,
    );
  }

  ({DateTime start, DateTime end}) resolveRange({
    DateTime? reference,
    int weekStartsOn = DateTime.monday,
    int monthStartDay = 1,
  }) {
    final now = reference ?? DateTime.now();
    return switch (period) {
      StatisticsPeriod.today => (
          start: AppDateUtils.startOfDay(now),
          end: AppDateUtils.endOfDay(now),
        ),
      StatisticsPeriod.week => (
          start: AppDateUtils.startOfWeek(now, weekStartsOn: weekStartsOn),
          end: AppDateUtils.endOfDay(now),
        ),
      StatisticsPeriod.month => (
          start: AppDateUtils.startOfBillingMonth(
            now,
            monthStartDay: monthStartDay,
          ),
          end: AppDateUtils.endOfDay(now),
        ),
      StatisticsPeriod.quarter => (
          start: _startOfQuarter(now),
          end: AppDateUtils.endOfDay(now),
        ),
      StatisticsPeriod.year => (
          start: AppDateUtils.startOfYear(now),
          end: AppDateUtils.endOfDay(now),
        ),
      StatisticsPeriod.all => (
          start: DateTime(2000, 1, 1),
          end: AppDateUtils.endOfDay(now),
        ),
      StatisticsPeriod.custom => (
          start: AppDateUtils.startOfDay(customStart ?? now),
          end: AppDateUtils.endOfDay(customEnd ?? customStart ?? now),
        ),
    };
  }

  DateTime _startOfQuarter(DateTime date) {
    final quarterMonth = ((date.month - 1) ~/ 3) * 3 + 1;
    return DateTime(date.year, quarterMonth);
  }

  static String periodLabelFor(StatisticsPeriod period) {
    return switch (period) {
      StatisticsPeriod.today => '今日',
      StatisticsPeriod.week => '本周',
      StatisticsPeriod.month => '本月',
      StatisticsPeriod.quarter => '本季',
      StatisticsPeriod.year => '本年',
      StatisticsPeriod.all => '全部',
      StatisticsPeriod.custom => '自定义',
    };
  }

  String periodLabel() {
    return switch (period) {
      StatisticsPeriod.today => '今日',
      StatisticsPeriod.week => '本周',
      StatisticsPeriod.month => '本月',
      StatisticsPeriod.quarter => '本季',
      StatisticsPeriod.year => '本年',
      StatisticsPeriod.all => '全部',
      StatisticsPeriod.custom => '自定义',
    };
  }
}

class StatisticsFilterNotifier extends StateNotifier<StatisticsFilter> {
  StatisticsFilterNotifier() : super(const StatisticsFilter());

  Timer? _keywordDebounce;

  @override
  void dispose() {
    _keywordDebounce?.cancel();
    super.dispose();
  }

  void setPeriod(StatisticsPeriod period) {
    state = state.copyWith(period: period);
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = StatisticsFilter(
      period: StatisticsPeriod.custom,
      customStart: start,
      customEnd: end,
      transactionType: state.transactionType,
      accountId: state.accountId,
      bookId: state.bookId,
      keyword: state.keyword,
    );
  }

  void setTransactionType(TransactionType? type) {
    state = state.copyWith(
      transactionType: type,
      clearTransactionType: type == null,
    );
  }

  void setAccountId(int? accountId) {
    state = state.copyWith(
      accountId: accountId,
      clearAccountId: accountId == null,
    );
  }

  void setBookId(int? bookId) {
    state = state.copyWith(
      bookId: bookId,
      clearBookId: bookId == null,
      clearAccountId: true,
    );
  }

  void setKeyword(String keyword) {
    _keywordDebounce?.cancel();
    if (keyword.trim().isEmpty) {
      if (state.keyword.isNotEmpty) {
        state = state.copyWith(keyword: '');
      }
      return;
    }
    _keywordDebounce = Timer(const Duration(milliseconds: 300), () {
      if (state.keyword != keyword) {
        state = state.copyWith(keyword: keyword);
      }
    });
  }
}

final statisticsFilterProvider =
    StateNotifierProvider<StatisticsFilterNotifier, StatisticsFilter>(
  (ref) => StatisticsFilterNotifier(),
);
