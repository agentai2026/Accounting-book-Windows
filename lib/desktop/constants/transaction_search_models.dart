import 'package:ezbookkeeping_desktop/core/database/daos/transaction_dao.dart';
import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/transaction_search_query_builder.dart';

/// 「其他」区域的快捷筛选标签
enum TransactionSearchQuickFilter {
  expense,
  income,
  allReimbursable,
  pendingReimbursement,
  reimbursed,
  notReimbursable,
  refund,
  transfer,
  repayment,
  collection,
  borrowIn,
  borrowOut,
  investment,
  recurring,
  withAttachment,
  excludeFromIo,
  onlyIo,
  excludeBudget,
  onlyBudget,
}

extension TransactionSearchQuickFilterX on TransactionSearchQuickFilter {
  String get label => switch (this) {
        TransactionSearchQuickFilter.expense => '支出',
        TransactionSearchQuickFilter.income => '收入',
        TransactionSearchQuickFilter.allReimbursable => '所有报销',
        TransactionSearchQuickFilter.pendingReimbursement => '待报销',
        TransactionSearchQuickFilter.reimbursed => '已报销',
        TransactionSearchQuickFilter.notReimbursable => '不报销',
        TransactionSearchQuickFilter.refund => '退款',
        TransactionSearchQuickFilter.transfer => '转账',
        TransactionSearchQuickFilter.repayment => '还款',
        TransactionSearchQuickFilter.collection => '收款',
        TransactionSearchQuickFilter.borrowIn => '借入',
        TransactionSearchQuickFilter.borrowOut => '借出',
        TransactionSearchQuickFilter.investment => '理财',
        TransactionSearchQuickFilter.recurring => '重复账单',
        TransactionSearchQuickFilter.withAttachment => '带附件',
        TransactionSearchQuickFilter.excludeFromIo => '不计入收支',
        TransactionSearchQuickFilter.onlyIo => '仅计入收支',
        TransactionSearchQuickFilter.excludeBudget => '不计入预算',
        TransactionSearchQuickFilter.onlyBudget => '仅计入预算',
      };

  /// 是否已接入数据库查询
  bool get isQueryable => true;
}

/// 收支口径快捷筛选（互斥）
const ioScopeQuickFilters = {
  TransactionSearchQuickFilter.excludeFromIo,
  TransactionSearchQuickFilter.onlyIo,
};

/// 预算口径快捷筛选（互斥）
const budgetScopeQuickFilters = {
  TransactionSearchQuickFilter.excludeBudget,
  TransactionSearchQuickFilter.onlyBudget,
};

/// 报销行专用筛选（与「其他」中报销类标签联动）
const reimbursementQuickFilters = {
  TransactionSearchQuickFilter.allReimbursable,
  TransactionSearchQuickFilter.pendingReimbursement,
  TransactionSearchQuickFilter.reimbursed,
  TransactionSearchQuickFilter.notReimbursable,
};

class TransactionSearchCriteria {
  const TransactionSearchCriteria({
    this.keyword = '',
    this.minAmountText = '',
    this.maxAmountText = '',
    this.startDate,
    this.endDate,
    this.bookIds = const [],
    this.accountIds = const [],
    this.categoryIds = const [],
    this.tagIds = const [],
    this.quickFilters = const {},
    this.page = 0,
    this.pageSize = 50,
  });

  final String keyword;
  final String minAmountText;
  final String maxAmountText;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<int> bookIds;
  final List<int> accountIds;
  final List<int> categoryIds;
  final List<int> tagIds;
  final Set<TransactionSearchQuickFilter> quickFilters;
  final int page;
  final int pageSize;

  TransactionSearchCriteria copyWith({
    String? keyword,
    String? minAmountText,
    String? maxAmountText,
    DateTime? startDate,
    DateTime? endDate,
    List<int>? bookIds,
    List<int>? accountIds,
    List<int>? categoryIds,
    List<int>? tagIds,
    Set<TransactionSearchQuickFilter>? quickFilters,
    int? page,
    int? pageSize,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return TransactionSearchCriteria(
      keyword: keyword ?? this.keyword,
      minAmountText: minAmountText ?? this.minAmountText,
      maxAmountText: maxAmountText ?? this.maxAmountText,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      bookIds: bookIds ?? this.bookIds,
      accountIds: accountIds ?? this.accountIds,
      categoryIds: categoryIds ?? this.categoryIds,
      tagIds: tagIds ?? this.tagIds,
      quickFilters: quickFilters ?? this.quickFilters,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  TransactionType? get resolvedType {
    if (quickFilters.contains(TransactionSearchQuickFilter.expense)) {
      return TransactionType.expense;
    }
    if (quickFilters.contains(TransactionSearchQuickFilter.income)) {
      return TransactionType.income;
    }
    if (quickFilters.contains(TransactionSearchQuickFilter.transfer)) {
      return TransactionType.transfer;
    }
    return null;
  }

  bool? get resolvedReimbursable {
    if (quickFilters.contains(TransactionSearchQuickFilter.notReimbursable)) {
      return false;
    }
    if (quickFilters.contains(TransactionSearchQuickFilter.pendingReimbursement) ||
        quickFilters.contains(TransactionSearchQuickFilter.allReimbursable) ||
        quickFilters.contains(TransactionSearchQuickFilter.reimbursed)) {
      return true;
    }
    return null;
  }

  bool get requireReimbursedTag =>
      quickFilters.contains(TransactionSearchQuickFilter.reimbursed);

  bool get excludeReimbursedTag =>
      quickFilters.contains(TransactionSearchQuickFilter.pendingReimbursement);

  (DateTime?, DateTime?) get resolvedDateRange => (
        startDate == null ? null : AppDateUtils.startOfDay(startDate!),
        endDate == null ? null : AppDateUtils.endOfDay(endDate!),
      );

  int? parseAmountCents(String text) => _parseCents(text);

  int? _parseCents(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final value = double.tryParse(trimmed.replaceAll(',', ''));
    if (value == null) return null;
    return (value * 100).round();
  }

  /// 在已应用筛选条件下，查询某一天是否有账单
  TransactionQuery toCountQueryForDay(
    DateTime day, {
    int? bookIdFallback,
    List<Category> categories = const [],
    Set<int> budgetCategoryIds = const {},
  }) {
    final (filterStart, filterEnd) = resolvedDateRange;
    final dayStart = AppDateUtils.startOfDay(day);
    final dayEnd = AppDateUtils.endOfDay(day);

    var rangeStart = dayStart;
    var rangeEnd = dayEnd;
    if (filterStart != null && filterStart.isAfter(rangeStart)) {
      rangeStart = filterStart;
    }
    if (filterEnd != null && filterEnd.isBefore(rangeEnd)) {
      rangeEnd = filterEnd;
    }

    return TransactionSearchQueryBuilder.build(
      criteria: this,
      bookIdFallback: bookIdFallback,
      categories: categories,
      budgetCategoryIds: budgetCategoryIds,
      startDate: rangeStart,
      endDate: rangeEnd,
      limit: 1,
      offset: 0,
    );
  }

  /// 在已应用筛选条件下，汇总某一自然月的收支（与列表分页无关）
  TransactionQuery toSumQueryForMonth(
    DateTime month, {
    int? bookIdFallback,
    List<Category> categories = const [],
    Set<int> budgetCategoryIds = const {},
  }) {
    final (filterStart, filterEnd) = resolvedDateRange;
    final monthStart = AppDateUtils.startOfMonth(month);
    final monthEnd = AppDateUtils.endOfMonth(month);

    var rangeStart = monthStart;
    var rangeEnd = monthEnd;
    if (filterStart != null && filterStart.isAfter(rangeStart)) {
      rangeStart = filterStart;
    }
    if (filterEnd != null && filterEnd.isBefore(rangeEnd)) {
      rangeEnd = filterEnd;
    }

    return TransactionSearchQueryBuilder.build(
      criteria: this,
      bookIdFallback: bookIdFallback,
      categories: categories,
      budgetCategoryIds: budgetCategoryIds,
      startDate: rangeStart,
      endDate: rangeEnd,
      limit: 1,
      offset: 0,
    );
  }

  bool isDayWithinAppliedRange(DateTime day) {
    final (filterStart, filterEnd) = resolvedDateRange;
    final dayStart = AppDateUtils.startOfDay(day);
    final dayEnd = AppDateUtils.endOfDay(day);
    if (filterStart != null && dayEnd.isBefore(filterStart)) return false;
    if (filterEnd != null && dayStart.isAfter(filterEnd)) return false;
    return true;
  }

  TransactionQuery toQuery({
    int? bookIdFallback,
    List<Category> categories = const [],
    Set<int> budgetCategoryIds = const {},
  }) {
    return TransactionSearchQueryBuilder.build(
      criteria: this,
      bookIdFallback: bookIdFallback,
      categories: categories,
      budgetCategoryIds: budgetCategoryIds,
    );
  }

  int get activeFilterCount {
    var count = 0;
    if (keyword.trim().isNotEmpty) count++;
    if (minAmountText.trim().isNotEmpty || maxAmountText.trim().isNotEmpty) {
      count++;
    }
    if (startDate != null || endDate != null) count++;
    count += bookIds.length +
        accountIds.length +
        categoryIds.length +
        tagIds.length;
    count += quickFilters.length;
    return count;
  }
}
