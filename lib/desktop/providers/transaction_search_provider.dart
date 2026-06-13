import 'package:flutter_riverpod/flutter_riverpod.dart';



import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/services/statistics_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';

import 'package:ezbookkeeping_desktop/desktop/constants/transaction_search_models.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/budget_provider.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/transaction_provider.dart';



class TransactionSearchState {

  const TransactionSearchState({

    this.draft = const TransactionSearchCriteria(),

    this.applied = const TransactionSearchCriteria(),

    this.hasSearched = false,

    this.selectedTransactionId,

    this.searchToken = 0,

  });



  final TransactionSearchCriteria draft;

  final TransactionSearchCriteria applied;

  final bool hasSearched;

  final int? selectedTransactionId;



  /// 每次点击「搜索」递增，用于触发结果列表从头加载

  final int searchToken;



  TransactionSearchState copyWith({

    TransactionSearchCriteria? draft,

    TransactionSearchCriteria? applied,

    bool? hasSearched,

    int? selectedTransactionId,

    int? searchToken,

    bool clearSelection = false,

  }) {

    return TransactionSearchState(

      draft: draft ?? this.draft,

      applied: applied ?? this.applied,

      hasSearched: hasSearched ?? this.hasSearched,

      selectedTransactionId:

          clearSelection ? null : (selectedTransactionId ?? this.selectedTransactionId),

      searchToken: searchToken ?? this.searchToken,

    );

  }

}



class TransactionSearchNotifier extends StateNotifier<TransactionSearchState> {

  TransactionSearchNotifier() : super(const TransactionSearchState());



  void patchDraft(

    TransactionSearchCriteria Function(TransactionSearchCriteria) fn,

  ) {

    state = state.copyWith(draft: fn(state.draft));

  }



  void reset() {

    state = const TransactionSearchState();

  }



  void search() {

    state = state.copyWith(

      applied: state.draft,

      draft: state.draft,

      hasSearched: true,

      searchToken: state.searchToken + 1,

      clearSelection: true,

    );

  }



  void selectTransaction(int? id) {

    state = state.copyWith(selectedTransactionId: id);

  }



  void toggleQuickFilter(TransactionSearchQuickFilter filter) {

    patchDraft((draft) {

      final next = Set<TransactionSearchQuickFilter>.from(draft.quickFilters);

      if (next.contains(filter)) {

        next.remove(filter);

      } else {

        if (filter == TransactionSearchQuickFilter.expense ||

            filter == TransactionSearchQuickFilter.income ||

            filter == TransactionSearchQuickFilter.transfer) {

          next.removeWhere(

            (f) =>

                f == TransactionSearchQuickFilter.expense ||

                f == TransactionSearchQuickFilter.income ||

                f == TransactionSearchQuickFilter.transfer,

          );

        }

        if (reimbursementQuickFilters.contains(filter)) {

          next.removeWhere(reimbursementQuickFilters.contains);

        }

        if (ioScopeQuickFilters.contains(filter)) {

          next.removeWhere(ioScopeQuickFilters.contains);

        }

        if (budgetScopeQuickFilters.contains(filter)) {

          next.removeWhere(budgetScopeQuickFilters.contains);

        }

        next.add(filter);

      }

      return draft.copyWith(quickFilters: next);

    });

  }

}



Future<({List<Category> categories, Set<int> budgetCategoryIds})>
    _searchQueryContext(Ref ref) async {
  final categories = await ref.read(allCategoriesProvider.future);
  final budgets = await ref.read(budgetListProvider.future);
  final bookId = ref.read(activeBookIdProvider);
  final budgetCategoryIds = {
    for (final budget in budgets)
      if (budget.deletedAt == null &&
          budget.categoryId != null &&
          (bookId == null || budget.bookId == bookId))
        budget.categoryId!,
  };
  return (categories: categories, budgetCategoryIds: budgetCategoryIds);
}

final _searchQueryContextProvider =
    FutureProvider<({List<Category> categories, Set<int> budgetCategoryIds})>(
  (ref) => _searchQueryContext(ref),
);

final transactionSearchProvider =

    StateNotifierProvider<TransactionSearchNotifier, TransactionSearchState>(

  (ref) => TransactionSearchNotifier(),

);



class SearchResultsBundle {

  const SearchResultsBundle({

    required this.rows,

    required this.totalCount,

    required this.page,

    required this.pageSize,

    required this.summary,

    this.isLoadingMore = false,

  });



  const SearchResultsBundle.empty()

      : rows = const [],

        totalCount = 0,

        page = 0,

        pageSize = 50,

        summary = const PeriodSummary(expenseCents: 0, incomeCents: 0),

        isLoadingMore = false;



  final List<TransactionRowData> rows;

  final int totalCount;

  final int page;

  final int pageSize;

  final PeriodSummary summary;

  final bool isLoadingMore;



  bool get hasMore => rows.length < totalCount;



  SearchResultsBundle copyWith({

    List<TransactionRowData>? rows,

    int? totalCount,

    int? page,

    int? pageSize,

    PeriodSummary? summary,

    bool? isLoadingMore,

  }) {

    return SearchResultsBundle(

      rows: rows ?? this.rows,

      totalCount: totalCount ?? this.totalCount,

      page: page ?? this.page,

      pageSize: pageSize ?? this.pageSize,

      summary: summary ?? this.summary,

      isLoadingMore: isLoadingMore ?? this.isLoadingMore,

    );

  }

}



class TransactionSearchResultsNotifier

    extends StateNotifier<AsyncValue<SearchResultsBundle>> {

  TransactionSearchResultsNotifier(this._ref)

      : super(const AsyncValue.data(SearchResultsBundle.empty())) {

    _ref.listen<int>(

      transactionSearchProvider.select((s) => s.searchToken),

      (previous, next) {

        if (next == 0) return;

        _reload();

      },

    );

    _ref.listen(transactionRefreshProvider, (previous, next) {

      final searchState = _ref.read(transactionSearchProvider);

      if (searchState.hasSearched) {

        _reload();

      }

    });

  }



  final Ref _ref;

  bool _loadingMore = false;



  Future<void> _reload() async {

    final searchState = _ref.read(transactionSearchProvider);

    if (!searchState.hasSearched) {

      state = const AsyncValue.data(SearchResultsBundle.empty());

      return;

    }



    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() => _fetchPage(page: 0, append: false));

  }



  Future<void> loadMore() async {

    final current = state.valueOrNull;

    if (current == null || !current.hasMore || _loadingMore || current.isLoadingMore) {

      return;

    }



    _loadingMore = true;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));



    final nextPage = current.page + 1;

    final result = await AsyncValue.guard(

      () => _fetchPage(page: nextPage, append: true, previous: current),

    );



    _loadingMore = false;

    state = result;

  }



  Future<SearchResultsBundle> _fetchPage({

    required int page,

    required bool append,

    SearchResultsBundle? previous,

  }) async {

    final searchState = _ref.read(transactionSearchProvider);

    final bookId = _ref.read(activeBookIdProvider);

    final criteria = searchState.applied.copyWith(page: page);

    final ctx = await _searchQueryContext(_ref);

    final query = criteria.toQuery(
      bookIdFallback: bookId,
      categories: ctx.categories,
      budgetCategoryIds: ctx.budgetCategoryIds,
    );

    final dao = await _ref.read(transactionDaoProvider.future);



    final rows = await dao.search(query);

    final rowData = await buildTransactionRowData(_ref, rows);



    if (!append) {

      final count = await dao.countQuery(query);
      final totals = await dao.sumIncomeExpenseQuery(query);

      return SearchResultsBundle(

        rows: rowData,

        totalCount: count,

        page: page,

        pageSize: criteria.pageSize,

        summary: PeriodSummary(

          expenseCents: totals.expenseCents,

          incomeCents: totals.incomeCents,

        ),

      );

    }



    final base = previous ?? const SearchResultsBundle.empty();

    return base.copyWith(

      rows: [...base.rows, ...rowData],

      page: page,

      isLoadingMore: false,

    );

  }

  Future<bool> hasTransactionsOnDay(DateTime day) async {
    final searchState = _ref.read(transactionSearchProvider);
    if (!searchState.hasSearched) return false;
    if (!searchState.applied.isDayWithinAppliedRange(day)) return false;

    final criteria = searchState.applied;
    final ctx = await _searchQueryContext(_ref);
    final query = criteria.toCountQueryForDay(
      day,
      bookIdFallback: _ref.read(activeBookIdProvider),
      categories: ctx.categories,
      budgetCategoryIds: ctx.budgetCategoryIds,
    );
    if (query.startDate != null &&
        query.endDate != null &&
        query.startDate!.isAfter(query.endDate!)) {
      return false;
    }

    final dao = await _ref.read(transactionDaoProvider.future);
    final count = await dao.countQuery(query);
    return count > 0;
  }

  Future<bool> loadUntilContainsDay(DateTime day) async {
    final target = AppDateUtils.startOfDay(day);
    for (var i = 0; i < 60; i++) {
      final current = state.valueOrNull;
      if (current == null) return false;
      if (_rowsContainDay(current.rows, target)) return true;
      if (!current.hasMore) return false;
      await loadMore();
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    final finalRows = state.valueOrNull?.rows ?? const [];
    return _rowsContainDay(finalRows, target);
  }

  bool _rowsContainDay(List<TransactionRowData> rows, DateTime target) {
    for (final row in rows) {
      final d = AppDateUtils.startOfDay(row.transaction.date);
      if (d.year == target.year &&
          d.month == target.month &&
          d.day == target.day) {
        return true;
      }
    }
    return false;
  }

}



final transactionSearchResultsProvider = StateNotifierProvider<

    TransactionSearchResultsNotifier, AsyncValue<SearchResultsBundle>>(

  (ref) => TransactionSearchResultsNotifier(ref),

);

/// 搜索列表当前可见月份的收支汇总（数据库聚合，不依赖已加载行）
final searchVisibleMonthSummaryProvider =
    FutureProvider.family<PeriodSummary, SearchMonthAnchor>((ref, anchor) async {
  ref.watch(transactionSearchProvider.select((s) => s.searchToken));
  final searchState = ref.read(transactionSearchProvider);
  if (!searchState.hasSearched) {
    return const PeriodSummary(expenseCents: 0, incomeCents: 0);
  }

  final month = DateTime(anchor.year, anchor.month);
  final ctx = await ref.read(_searchQueryContextProvider.future);
  final query = searchState.applied.toSumQueryForMonth(
    month,
    bookIdFallback: ref.read(activeBookIdProvider),
    categories: ctx.categories,
    budgetCategoryIds: ctx.budgetCategoryIds,
  );
  if (query.startDate != null &&
      query.endDate != null &&
      query.startDate!.isAfter(query.endDate!)) {
    return const PeriodSummary(expenseCents: 0, incomeCents: 0);
  }

  final dao = await ref.read(transactionDaoProvider.future);
  final totals = await dao.sumIncomeExpenseQuery(query);
  return PeriodSummary(
    expenseCents: totals.expenseCents,
    incomeCents: totals.incomeCents,
  );
});

class SearchMonthAnchor {
  const SearchMonthAnchor({required this.year, required this.month});

  final int year;
  final int month;

  @override
  bool operator ==(Object other) =>
      other is SearchMonthAnchor && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

/// 搜索详情：关联账单
final relatedTransactionRowsProvider =
    FutureProvider.family<List<TransactionRowData>, int>((ref, transactionId) async {
  ref.watch(transactionRefreshProvider);
  final dao = await ref.read(transactionDaoProvider.future);
  final tx = await dao.getById(transactionId);
  if (tx == null) return const [];
  final related = await dao.findRelatedTransactions(tx);
  if (related.isEmpty) return const [];
  return buildTransactionRowData(ref, related);
});


