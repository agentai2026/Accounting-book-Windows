import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TransactionDetailView { list, calendar, album }

class TransactionFilterState {
  TransactionFilterState({
    this.keyword = '',
    this.type,
    this.page = 0,
    this.pageSize = 15,
    DateTime? selectedMonth,
    this.customRangeStart,
    this.customRangeEnd,
    this.view = TransactionDetailView.list,
    this.showAllPeriod = false,
  }) : selectedMonth = selectedMonth ?? _defaultMonth();

  final String keyword;
  final TransactionType? type;
  final int page;
  final int pageSize;
  final DateTime selectedMonth;
  final DateTime? customRangeStart;
  final DateTime? customRangeEnd;
  final TransactionDetailView view;
  final bool showAllPeriod;

  static DateTime _defaultMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  bool get usesCustomRange =>
      customRangeStart != null && customRangeEnd != null;

  DateTime get rangeStart => usesCustomRange
      ? AppDateUtils.startOfDay(customRangeStart!)
      : AppDateUtils.startOfMonth(selectedMonth);

  DateTime get rangeEnd => usesCustomRange
      ? AppDateUtils.endOfDay(customRangeEnd!)
      : AppDateUtils.endOfMonth(selectedMonth);

  TransactionFilterState copyWith({
    String? keyword,
    TransactionType? type,
    int? page,
    int? pageSize,
    DateTime? selectedMonth,
    DateTime? customRangeStart,
    DateTime? customRangeEnd,
    TransactionDetailView? view,
    bool? showAllPeriod,
    bool clearType = false,
    bool clearCustomRange = false,
  }) {
    return TransactionFilterState(
      keyword: keyword ?? this.keyword,
      type: clearType ? null : (type ?? this.type),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      customRangeStart:
          clearCustomRange ? null : (customRangeStart ?? this.customRangeStart),
      customRangeEnd:
          clearCustomRange ? null : (customRangeEnd ?? this.customRangeEnd),
      view: view ?? this.view,
      showAllPeriod: showAllPeriod ?? this.showAllPeriod,
    );
  }
}

class TransactionFilterNotifier extends StateNotifier<TransactionFilterState> {
  TransactionFilterNotifier() : super(TransactionFilterState());

  void setKeyword(String keyword) {
    state = state.copyWith(keyword: keyword, page: 0);
  }

  void setType(TransactionType? type) {
    state = state.copyWith(type: type, page: 0, clearType: type == null);
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
  }

  void setPageSize(int pageSize) {
    state = state.copyWith(pageSize: pageSize, page: 0);
  }

  void setView(TransactionDetailView view) {
    state = state.copyWith(view: view);
  }

  void setMonth(DateTime month) {
    state = state.copyWith(
      selectedMonth: DateTime(month.year, month.month),
      page: 0,
      clearCustomRange: true,
      showAllPeriod: false,
    );
  }

  void setShowAllPeriod() {
    state = state.copyWith(showAllPeriod: true, page: 0, clearCustomRange: true);
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = state.copyWith(
      customRangeStart: start,
      customRangeEnd: end,
      selectedMonth: DateTime(start.year, start.month),
      page: 0,
    );
  }

  void clearCustomRange() {
    state = state.copyWith(clearCustomRange: true, page: 0);
  }

  void prevMonth() {
    final m = state.selectedMonth;
    setMonth(DateTime(m.year, m.month - 1));
  }

  void nextMonth() {
    final m = state.selectedMonth;
    setMonth(DateTime(m.year, m.month + 1));
  }

  void reset() {
    state = TransactionFilterState();
  }
}

final transactionFilterProvider =
    StateNotifierProvider<TransactionFilterNotifier, TransactionFilterState>(
  (ref) => TransactionFilterNotifier(),
);

/// 用于在记账成功后刷新列表
final transactionRefreshProvider = StateProvider<int>((ref) => 0);
