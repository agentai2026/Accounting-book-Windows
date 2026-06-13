import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountRefreshProvider = StateProvider<int>((ref) => 0);

final accountListProvider = FutureProvider<List<Account>>((ref) async {
  ref.watch(transactionRefreshProvider);
  ref.watch(accountRefreshProvider);
  final bookId = ref.watch(activeBookIdProvider);
  final dao = await ref.watch(accountDaoProvider.future);
  return dao.getAll(bookId: bookId);
});

final accountListForBookProvider =
    FutureProvider.family<List<Account>, int?>((ref, bookId) async {
  ref.watch(accountRefreshProvider);
  ref.watch(transactionRefreshProvider);
  if (bookId == null) return [];
  final dao = await ref.watch(accountDaoProvider.future);
  return dao.getAll(bookId: bookId);
});

void refreshAccounts(WidgetRef ref) {
  ref.read(accountRefreshProvider.notifier).state++;
}
