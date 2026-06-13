import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/models/scheduled_transaction.dart';
import 'package:ezbookkeeping_desktop/core/models/transaction.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';

final scheduledTransactionRefreshProvider = StateProvider<int>((ref) => 0);

final scheduledTransactionListProvider =
    FutureProvider<List<ScheduledTransaction>>((ref) async {
  ref.watch(scheduledTransactionRefreshProvider);
  ref.watch(activeBookIdProvider);
  final dao = await ref.watch(scheduledTransactionDaoProvider.future);
  final bookId = ref.watch(activeBookIdProvider);
  return dao.getAll(bookId: bookId);
});

final scheduledTransactionRunCountProvider =
    FutureProvider.family<int, int>((ref, scheduledId) async {
  ref.watch(transactionRefreshProvider);
  ref.watch(scheduledTransactionRefreshProvider);
  final dao = await ref.read(transactionDaoProvider.future);
  return dao.countByScheduledTransactionId(scheduledId);
});

final scheduledTransactionRunsProvider =
    FutureProvider.family<List<Transaction>, int>((ref, scheduledId) async {
  ref.watch(transactionRefreshProvider);
  ref.watch(scheduledTransactionRefreshProvider);
  final dao = await ref.read(transactionDaoProvider.future);
  return dao.getByScheduledTransactionId(scheduledId);
});

void refreshScheduledTransactions(WidgetRef ref) {
  ref.read(scheduledTransactionRefreshProvider.notifier).state++;
  ref.read(transactionRefreshProvider.notifier).state++;
}
