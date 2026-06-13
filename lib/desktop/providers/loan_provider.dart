import 'package:ezbookkeeping_desktop/core/models/loan.dart';
import 'package:ezbookkeeping_desktop/core/services/budget_service.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loanRefreshProvider = StateProvider<int>((ref) => 0);

final loanListProvider = FutureProvider<List<Loan>>((ref) async {
  ref.watch(loanRefreshProvider);
  final bookId = ref.watch(activeBookIdProvider);
  final dao = await ref.watch(loanDaoProvider.future);
  return dao.getAll(bookId: bookId);
});

void refreshLoans(WidgetRef ref) {
  ref.read(loanRefreshProvider.notifier).state++;
}

final budgetRefreshProvider = StateProvider<int>((ref) => 0);

final budgetProgressListProvider =
    FutureProvider<List<BudgetWithProgress>>((ref) async {
  ref.watch(budgetRefreshProvider);
  ref.watch(transactionRefreshProvider);
  final bookId = ref.watch(activeBookIdProvider);
  if (bookId == null) return [];

  final categories = await ref.watch(allCategoriesProvider.future);
  final categoryNames = {
    for (final category in categories)
      if (category.id != null) category.id!: category.name,
  };

  final service = await ref.watch(budgetServiceProvider.future);
  final monthStartDay = ref.watch(monthStartDayProvider);
  return service.getBudgetsWithProgress(
    bookId: bookId,
    categoryNames: categoryNames,
    monthStartDay: monthStartDay,
  );
});

void refreshBudgets(WidgetRef ref) {
  ref.read(budgetRefreshProvider.notifier).state++;
}
