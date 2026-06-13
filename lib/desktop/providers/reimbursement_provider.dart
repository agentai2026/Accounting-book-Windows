import 'package:ezbookkeeping_desktop/core/constants/transaction_flag_tags.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/transaction_dao.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/services/reimbursement_service.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/account_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const kReimbursementPageSize = 50;

enum ReimbursementListTab {
  pending,
  reimbursed,
  all,
}

extension ReimbursementListTabX on ReimbursementListTab {
  String get label => switch (this) {
        ReimbursementListTab.pending => '待报销',
        ReimbursementListTab.reimbursed => '已报销',
        ReimbursementListTab.all => '全部',
      };

  ReimbursementStatus get status => switch (this) {
        ReimbursementListTab.pending => ReimbursementStatus.pending,
        ReimbursementListTab.reimbursed => ReimbursementStatus.reimbursed,
        ReimbursementListTab.all => ReimbursementStatus.all,
      };
}

class ReimbursementListBundle {
  const ReimbursementListBundle({
    required this.rows,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  const ReimbursementListBundle.empty()
      : rows = const [],
        hasMore = false,
        isLoadingMore = false;

  final List<TransactionRowData> rows;
  final bool hasMore;
  final bool isLoadingMore;

  ReimbursementListBundle copyWith({
    List<TransactionRowData>? rows,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ReimbursementListBundle(
      rows: rows ?? this.rows,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final reimbursementRefreshProvider = StateProvider<int>((ref) => 0);

final reimbursementTabProvider =
    StateProvider<ReimbursementListTab>((ref) => ReimbursementListTab.pending);

final reimbursementSummaryProvider =
    FutureProvider<ReimbursementSummary>((ref) async {
  ref.watch(reimbursementRefreshProvider);
  final bookId = ref.watch(activeBookIdProvider);
  final service = await ref.watch(reimbursementServiceProvider.future);
  final result = await service.getSummary(bookId: bookId);
  return result.when(
    success: (summary) => summary,
    failure: (error) => throw error,
  );
});

final reimbursementListProvider =
    AsyncNotifierProvider<ReimbursementListNotifier, ReimbursementListBundle>(
  ReimbursementListNotifier.new,
);

class ReimbursementListNotifier extends AsyncNotifier<ReimbursementListBundle> {
  bool _loadingMore = false;

  @override
  Future<ReimbursementListBundle> build() async {
    ref.watch(reimbursementRefreshProvider);
    ref.watch(reimbursementTabProvider);
    return _fetchPage(offset: 0, append: false);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null ||
        !current.hasMore ||
        _loadingMore ||
        current.isLoadingMore) {
      return;
    }

    _loadingMore = true;
    state = AsyncValue.data(current.copyWith(isLoadingMore: true));

    final result = await AsyncValue.guard(
      () => _fetchPage(
        offset: current.rows.length,
        append: true,
        previous: current,
      ),
    );

    _loadingMore = false;
    state = result;
  }

  Future<ReimbursementListBundle> _fetchPage({
    required int offset,
    required bool append,
    ReimbursementListBundle? previous,
  }) async {
    final tab = ref.read(reimbursementTabProvider);
    final bookId = ref.read(activeBookIdProvider);
    final currencyCode = ref.read(currencyCodeProvider);

    final dao = await ref.read(transactionDaoProvider.future);
    final categories = await ref.read(allCategoriesProvider.future);
    final accounts = await ref.read(accountListProvider.future);
    final tagDao = await ref.read(tagDaoProvider.future);

    final query = TransactionQuery(
      bookId: bookId,
      type: TransactionType.expense,
      isReimbursable: true,
      requireReimbursedTag: tab == ReimbursementListTab.reimbursed,
      excludeReimbursedTag: tab == ReimbursementListTab.pending,
      limit: kReimbursementPageSize + 1,
      offset: offset,
    );

    final transactions = await dao.search(query);
    final hasMore = transactions.length > kReimbursementPageSize;
    final pageItems = hasMore
        ? transactions.sublist(0, kReimbursementPageSize)
        : transactions;

    final rowData = await mapTransactionsToRowData(
      list: pageItems,
      categories: categories,
      accounts: accounts,
      tagDao: tagDao,
      currencyCode: currencyCode,
    );

    if (!append) {
      return ReimbursementListBundle(rows: rowData, hasMore: hasMore);
    }

    final base = previous ?? const ReimbursementListBundle.empty();
    return ReimbursementListBundle(
      rows: [...base.rows, ...rowData],
      hasMore: hasMore,
    );
  }
}

void refreshReimbursements(WidgetRef ref) {
  ref.read(reimbursementRefreshProvider.notifier).state++;
  ref.invalidate(reimbursementListProvider);
}

void refreshReimbursementsGlobally(WidgetRef ref) {
  refreshReimbursements(ref);
  ref.read(transactionRefreshProvider.notifier).state++;
}

bool isTransactionReimbursed(TransactionRowData row) {
  return row.tagNames.contains(TransactionFlagTags.reimbursed);
}
