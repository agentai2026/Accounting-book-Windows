import 'package:ezbookkeeping_desktop/core/models/book.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/app_state.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookRefreshProvider = StateProvider<int>((ref) => 0);

final bookListProvider = FutureProvider<List<Book>>((ref) async {
  ref.watch(bookRefreshProvider);
  final dao = await ref.watch(bookDaoProvider.future);
  return dao.getAll();
});

final activeBookIdProvider = Provider<int?>((ref) {
  final selected = ref.watch(currentBookIdProvider);
  if (selected != null) return selected;

  final books = ref.watch(bookListProvider);
  return books.maybeWhen(
    data: (list) => list.isNotEmpty ? list.first.id : null,
    orElse: () => null,
  );
});

final activeBookProvider = FutureProvider<Book?>((ref) async {
  final bookId = ref.watch(activeBookIdProvider);
  if (bookId == null) return null;
  final dao = await ref.watch(bookDaoProvider.future);
  return dao.getById(bookId);
});

void refreshBooks(WidgetRef ref) {
  ref.read(bookRefreshProvider.notifier).state++;
}

void switchActiveBook(WidgetRef ref, int bookId) {
  ref.read(currentBookIdProvider.notifier).state = bookId;
  ref.read(transactionRefreshProvider.notifier).state++;
}

const kDefaultBookName = '默认账本';

/// 导入交易写入当前选中的账本；若无选中则取第一个账本。
Future<int?> resolveImportBookId(WidgetRef ref) async {
  final activeId = ref.read(activeBookIdProvider);
  if (activeId != null) return activeId;

  final books = await ref.read(bookListProvider.future);
  if (books.isEmpty) return null;
  return books.first.id;
}
