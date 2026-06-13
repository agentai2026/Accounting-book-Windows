import 'package:ezbookkeeping_desktop/core/database/daos/tag_dao.dart';
import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/transaction.dart';
import 'package:ezbookkeeping_desktop/core/services/statistics_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/transaction_display_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/account_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/statistics_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _hasSearchKeyword(TransactionFilterState filter) =>
    filter.keyword.trim().isNotEmpty;

(String?, DateTime?, DateTime?) _listQueryParams(TransactionFilterState filter) {
  final keyword = _hasSearchKeyword(filter) ? filter.keyword.trim() : null;
  if (filter.showAllPeriod) {
    return (keyword, null, null);
  }
  return (keyword, filter.rangeStart, filter.rangeEnd);
}

class TransactionRowData {
  const TransactionRowData({
    required this.transaction,
    required this.categoryName,
    required this.accountName,
    required this.amountText,
    required this.tagText,
    this.tagNames = const [],
    this.categoryIcon,
    this.importSourceLabel,
  });

  final Transaction transaction;
  final String categoryName;
  final String accountName;
  final String amountText;
  final String tagText;
  final List<String> tagNames;
  final IconData? categoryIcon;

  /// 导入平台：支付宝 / 微信（仅导入账单有值）
  final String? importSourceLabel;
}

/// 按 id 加载单条账单行（搜索详情选中项可能不在当前结果集）
final transactionRowByIdProvider =
    FutureProvider.family<TransactionRowData?, int>((ref, transactionId) async {
  ref.watch(transactionRefreshProvider);
  final dao = await ref.read(transactionDaoProvider.future);
  final tx = await dao.getById(transactionId);
  if (tx == null) return null;
  final rows = await buildTransactionRowData(ref, [tx]);
  return rows.isEmpty ? null : rows.first;
});

Future<List<TransactionRowData>> buildTransactionRowData(
  Ref ref,
  List<Transaction> list,
) async {
  final currencyCode = ref.read(currencyCodeProvider);
  final categories = await ref.read(allCategoriesProvider.future);
  final accounts = await ref.read(accountListProvider.future);
  final tagDao = await ref.read(tagDaoProvider.future);

  return mapTransactionsToRowData(
    list: list,
    categories: categories,
    accounts: accounts,
    tagDao: tagDao,
    currencyCode: currencyCode,
  );
}

Future<List<TransactionRowData>> mapTransactionsToRowData({
  required List<Transaction> list,
  required List<Category> categories,
  required List<Account> accounts,
  required TagDao tagDao,
  required String currencyCode,
}) async {
  final categoryMap = {
    for (final c in categories)
      if (c.id != null) c.id!: c,
  };
  final accountMap = {
    for (final a in accounts)
      if (a.id != null) a.id!: a.name,
  };

  final ids = list.map((t) => t.id).whereType<int>().toList();
  final tagMap = await tagDao.getTagNamesByTransactionIds(ids);

  return list.map((t) {
    final category = categoryMap[t.categoryId];
    final tags = t.id == null ? null : tagMap[t.id!];
    final mappedAccount = _accountLabel(t, accountMap);
    return TransactionRowData(
      transaction: t,
      categoryName: category?.name ?? '未知分类',
      categoryIcon: category?.icon != null
          ? _categoryIconFromName(category!.icon!)
          : null,
      accountName: TransactionDisplayUtils.resolveAccountLabel(
        transaction: t,
        mappedAccountName: mappedAccount,
      ),
      amountText: _amountLabel(t, currencyCode),
      tagText: (tags == null || tags.isEmpty) ? '无' : tags.join('、'),
      tagNames: tags ?? const [],
      importSourceLabel:
          TransactionDisplayUtils.resolveImportSourceLabel(t),
    );
  }).toList();
}

final transactionListProvider =
    FutureProvider<List<TransactionRowData>>((ref) async {
  ref.watch(transactionRefreshProvider);
  final bookId = ref.watch(activeBookIdProvider);
  final filter = ref.watch(transactionFilterProvider);

  final service = await ref.watch(bookkeepingServiceProvider.future);
  final (keyword, startDate, endDate) = _listQueryParams(filter);

  final result = await service.getTransactions(
    bookId: bookId,
    limit: filter.pageSize,
    offset: filter.page * filter.pageSize,
    type: filter.type,
    keyword: keyword,
    startDate: startDate,
    endDate: endDate,
  );

  return result.when(
    success: (list) => buildTransactionRowData(ref, list),
    failure: (error) => throw error,
  );
});

final transactionCountProvider = FutureProvider<int>((ref) async {
  ref.watch(transactionRefreshProvider);
  final bookId = ref.watch(activeBookIdProvider);
  final filter = ref.watch(transactionFilterProvider);
  final service = await ref.watch(bookkeepingServiceProvider.future);
  final (keyword, startDate, endDate) = _listQueryParams(filter);
  final result = await service.getTransactionCount(
    bookId: bookId,
    type: filter.type,
    keyword: keyword,
    startDate: startDate,
    endDate: endDate,
  );
  return result.when(success: (c) => c, failure: (error) => throw error);
});

final transactionPeriodSummaryProvider =
    FutureProvider<PeriodSummary>((ref) async {
  ref.watch(transactionRefreshProvider);
  final bookId = ref.watch(activeBookIdProvider);
  final filter = ref.watch(transactionFilterProvider);
  if (bookId == null) {
    return const PeriodSummary(expenseCents: 0, incomeCents: 0);
  }

  final (keyword, startDate, endDate) = _listQueryParams(filter);
  final dao = await ref.watch(transactionDaoProvider.future);
  final totals = await dao.sumIncomeExpense(
    bookId: bookId,
    type: filter.type,
    keyword: keyword,
    startDate: startDate,
    endDate: endDate,
  );
  return PeriodSummary(
    expenseCents: totals.expenseCents,
    incomeCents: totals.incomeCents,
  );
});

final transactionDayRowsProvider =
    FutureProvider.family<List<TransactionRowData>, DateTime>((ref, day) async {
  ref.watch(transactionRefreshProvider);
  final bookId = ref.watch(activeBookIdProvider);
  final filter = ref.watch(transactionFilterProvider);
  if (bookId == null) return [];

  final service = await ref.watch(bookkeepingServiceProvider.future);
  final result = await service.getTransactions(
    bookId: bookId,
    limit: 500,
    offset: 0,
    type: filter.type,
    keyword: filter.keyword.isEmpty ? null : filter.keyword,
    startDate: AppDateUtils.startOfDay(day),
    endDate: AppDateUtils.endOfDay(day),
  );

  return result.when(
    success: (list) => buildTransactionRowData(ref, list),
    failure: (error) => throw error,
  );
});

final transactionAlbumRowsProvider =
    FutureProvider<List<TransactionRowData>>((ref) async {
  ref.watch(transactionRefreshProvider);
  final bookId = ref.watch(activeBookIdProvider);
  final filter = ref.watch(transactionFilterProvider);
  if (bookId == null) return [];

  final service = await ref.watch(bookkeepingServiceProvider.future);
  final (keyword, startDate, endDate) = _listQueryParams(filter);
  final result = await service.getTransactions(
    bookId: bookId,
    limit: 500,
    offset: 0,
    type: filter.type,
    keyword: keyword,
    startDate: startDate,
    endDate: endDate,
  );

  return result.when(
    success: (list) async {
      final withImages =
          list.where((t) => t.images != null && t.images!.isNotEmpty).toList();
      return buildTransactionRowData(ref, withImages);
    },
    failure: (error) => throw error,
  );
});

final todayNetBalanceProvider = FutureProvider<int>((ref) async {
  ref.watch(transactionRefreshProvider);
  final bookId = ref.watch(activeBookIdProvider);
  if (bookId == null) return 0;
  final service = await ref.watch(bookkeepingServiceProvider.future);
  final result = await service.getTodayNetBalance(bookId);
  return result.when(success: (v) => v, failure: (error) => throw error);
});

String _accountLabel(Transaction t, Map<int, String> accountMap) {
  return switch (t.type) {
    TransactionType.expense =>
      accountMap[t.fromAccountId] ?? '未知账户',
    TransactionType.income => accountMap[t.toAccountId] ?? '未知账户',
    TransactionType.transfer =>
      '${accountMap[t.fromAccountId] ?? '?'} → ${accountMap[t.toAccountId] ?? '?'}',
  };
}

String _amountLabel(Transaction t, String currencyCode) {
  return switch (t.type) {
    TransactionType.expense => MoneyUtils.formatWithSign(
        t.amount,
        currencyCode: currencyCode,
        isExpense: true,
      ),
    TransactionType.income => MoneyUtils.formatWithSign(
        t.amount,
        currencyCode: currencyCode,
        isIncome: true,
      ),
    TransactionType.transfer =>
      MoneyUtils.format(t.amount, currencyCode: currencyCode),
  };
}

IconData _categoryIconFromName(String iconName) {
  return switch (iconName) {
    'restaurant' => Icons.restaurant_outlined,
    'directions_car' => Icons.directions_car_outlined,
    'shopping_cart' => Icons.shopping_cart_outlined,
    'home' => Icons.home_outlined,
    'movie' => Icons.movie_outlined,
    'local_hospital' => Icons.local_hospital_outlined,
    'school' => Icons.school_outlined,
    'payments' => Icons.payments_outlined,
    'card_giftcard' => Icons.card_giftcard_outlined,
    'trending_up' => Icons.trending_up,
    'swap_horiz' => Icons.swap_horiz,
    _ => Icons.label_outline,
  };
}

String transactionTypeLabel(TransactionType type) {
  return switch (type) {
    TransactionType.expense => '支出',
    TransactionType.income => '收入',
    TransactionType.transfer => '转账',
  };
}

String formatTransactionDate(DateTime date) => AppDateUtils.formatDate(date);
