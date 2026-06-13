import 'package:ezbookkeeping_desktop/core/database/daos/transaction_dao.dart';
import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/transaction_search_models.dart';

/// 快捷筛选 → 分类名 / 导入元数据关键词
const _quickFilterCategoryNames = <TransactionSearchQuickFilter, List<String>>{
  TransactionSearchQuickFilter.repayment: ['还款', '信用卡还款'],
  TransactionSearchQuickFilter.collection: ['收债', '礼品红包'],
  TransactionSearchQuickFilter.borrowIn: ['借入'],
  TransactionSearchQuickFilter.borrowOut: ['借出'],
  TransactionSearchQuickFilter.investment: ['投资收入', '投资贷款', '银行转账'],
};

const _quickFilterMetadataKeywords =
    <TransactionSearchQuickFilter, List<String>>{
  TransactionSearchQuickFilter.collection: ['收钱码收款'],
  TransactionSearchQuickFilter.investment: ['投资理财'],
};

const _categorySemanticQuickFilters = {
  TransactionSearchQuickFilter.repayment,
  TransactionSearchQuickFilter.collection,
  TransactionSearchQuickFilter.borrowIn,
  TransactionSearchQuickFilter.borrowOut,
  TransactionSearchQuickFilter.investment,
};

/// 将搜索条件与分类/预算上下文合成为 DAO 查询
class TransactionSearchQueryBuilder {
  TransactionSearchQueryBuilder._();

  static TransactionQuery build({
    required TransactionSearchCriteria criteria,
    int? bookIdFallback,
    List<Category> categories = const [],
    Set<int> budgetCategoryIds = const {},
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) {
    final bookId = criteria.bookIds.length == 1
        ? criteria.bookIds.first
        : (criteria.bookIds.isEmpty ? bookIdFallback : null);
    final (rangeStart, rangeEnd) = criteria.resolvedDateRange;

    final quickCategoryIds = _resolveQuickCategoryIds(
      criteria.quickFilters,
      categories,
    );
    final mergedCategoryIds = _mergeCategoryIds(
      criteria.categoryIds,
      quickCategoryIds,
    );

    final metadataKeywords = <String>{};
    for (final filter in criteria.quickFilters) {
      metadataKeywords.addAll(_quickFilterMetadataKeywords[filter] ?? const []);
    }

    final unionCategoryAndMetadata =
        quickCategoryIds.isNotEmpty && metadataKeywords.isNotEmpty;

    return TransactionQuery(
      bookId: bookId,
      bookIds: criteria.bookIds.length > 1 ? criteria.bookIds : const [],
      keyword: criteria.keyword.trim().isEmpty ? null : criteria.keyword.trim(),
      type: criteria.resolvedType,
      startDate: startDate ?? rangeStart,
      endDate: endDate ?? rangeEnd,
      minAmountCents: criteria.parseAmountCents(criteria.minAmountText),
      maxAmountCents: criteria.parseAmountCents(criteria.maxAmountText),
      accountIds: criteria.accountIds,
      categoryIds: mergedCategoryIds,
      tagIds: criteria.tagIds,
      isReimbursable: criteria.resolvedReimbursable,
      hasImages: criteria.quickFilters
              .contains(TransactionSearchQuickFilter.withAttachment)
          ? true
          : null,
      requireRefundTag:
          criteria.quickFilters.contains(TransactionSearchQuickFilter.refund),
      requireReimbursedTag: criteria.requireReimbursedTag,
      excludeReimbursedTag: criteria.excludeReimbursedTag,
      ioFilter: _resolveIoFilter(criteria.quickFilters),
      budgetFilter: _resolveBudgetFilter(criteria.quickFilters),
      budgetTrackedCategoryIds: budgetCategoryIds.toList(),
      metadataCategoryKeywords: metadataKeywords.toList(),
      unionCategoryAndMetadata: unionCategoryAndMetadata,
      requireDuplicateCandidate: criteria.quickFilters
          .contains(TransactionSearchQuickFilter.recurring),
      limit: limit ?? criteria.pageSize,
      offset: offset ?? criteria.page * criteria.pageSize,
    );
  }

  static TransactionIoFilter _resolveIoFilter(
    Set<TransactionSearchQuickFilter> filters,
  ) {
    if (filters.contains(TransactionSearchQuickFilter.excludeFromIo)) {
      return TransactionIoFilter.excludeFromTotals;
    }
    if (filters.contains(TransactionSearchQuickFilter.onlyIo)) {
      return TransactionIoFilter.onlyInTotals;
    }
    return TransactionIoFilter.any;
  }

  static TransactionBudgetFilter _resolveBudgetFilter(
    Set<TransactionSearchQuickFilter> filters,
  ) {
    if (filters.contains(TransactionSearchQuickFilter.excludeBudget)) {
      return TransactionBudgetFilter.excludeFromBudget;
    }
    if (filters.contains(TransactionSearchQuickFilter.onlyBudget)) {
      return TransactionBudgetFilter.onlyInBudget;
    }
    return TransactionBudgetFilter.any;
  }

  static List<int> _resolveQuickCategoryIds(
    Set<TransactionSearchQuickFilter> filters,
    List<Category> categories,
  ) {
    final names = <String>{};
    for (final filter in filters) {
      if (!_categorySemanticQuickFilters.contains(filter)) continue;
      names.addAll(_quickFilterCategoryNames[filter] ?? const []);
    }
    if (names.isEmpty) return const [];

    return [
      for (final category in categories)
        if (category.id != null && names.contains(category.name)) category.id!,
    ];
  }

  static List<int> _mergeCategoryIds(
    List<int> manualIds,
    List<int> quickIds,
  ) {
    if (manualIds.isEmpty) return quickIds;
    if (quickIds.isEmpty) return manualIds;
    final quickSet = quickIds.toSet();
    return manualIds.where(quickSet.contains).toList();
  }
}
