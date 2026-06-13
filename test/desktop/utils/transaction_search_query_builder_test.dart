import 'package:flutter_test/flutter_test.dart';

import 'package:ezbookkeeping_desktop/core/database/daos/transaction_dao.dart';
import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/transaction_search_models.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/transaction_search_query_builder.dart';

void main() {
  test('investment quick filter unions category ids and metadata keywords', () {
    final categories = <Category>[
      Category(
        id: 10,
        uuid: 'a',
        name: '银行转账',
        type: CategoryType.transfer,
        icon: '1',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ];

    final query = TransactionSearchQueryBuilder.build(
      criteria: const TransactionSearchCriteria(
        quickFilters: {TransactionSearchQuickFilter.investment},
      ),
      bookIdFallback: 1,
      categories: categories,
      budgetCategoryIds: {99},
    );

    expect(query.categoryIds, [10]);
    expect(query.metadataCategoryKeywords, contains('投资理财'));
    expect(query.unionCategoryAndMetadata, isTrue);
  });

  test('excludeFromIo maps to io filter', () {
    final query = TransactionSearchQueryBuilder.build(
      criteria: const TransactionSearchCriteria(
        quickFilters: {TransactionSearchQuickFilter.excludeFromIo},
      ),
    );

    expect(query.ioFilter, TransactionIoFilter.excludeFromTotals);
  });

  test('onlyBudget maps to budget filter with tracked categories', () {
    final query = TransactionSearchQueryBuilder.build(
      criteria: const TransactionSearchCriteria(
        quickFilters: {TransactionSearchQuickFilter.onlyBudget},
      ),
      budgetCategoryIds: {3, 5},
    );

    expect(query.budgetFilter, TransactionBudgetFilter.onlyInBudget);
    expect(query.budgetTrackedCategoryIds, [3, 5]);
  });

  test('reimbursed quick filter requires reimbursable expenses with tag', () {
    const criteria = TransactionSearchCriteria(
      quickFilters: {TransactionSearchQuickFilter.reimbursed},
    );

    expect(criteria.resolvedReimbursable, isTrue);
    expect(criteria.requireReimbursedTag, isTrue);
    expect(criteria.excludeReimbursedTag, isFalse);
  });

  test('pending reimbursement excludes reimbursed tag', () {
    const criteria = TransactionSearchCriteria(
      quickFilters: {TransactionSearchQuickFilter.pendingReimbursement},
    );

    expect(criteria.resolvedReimbursable, isTrue);
    expect(criteria.requireReimbursedTag, isFalse);
    expect(criteria.excludeReimbursedTag, isTrue);
  });

  test('all reimbursable includes reimbursed and pending', () {
    const criteria = TransactionSearchCriteria(
      quickFilters: {TransactionSearchQuickFilter.allReimbursable},
    );

    expect(criteria.resolvedReimbursable, isTrue);
    expect(criteria.requireReimbursedTag, isFalse);
    expect(criteria.excludeReimbursedTag, isFalse);
  });
}
