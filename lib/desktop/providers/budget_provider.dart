import 'package:ezbookkeeping_desktop/core/models/budget.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/loan_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final budgetListProvider = FutureProvider<List<Budget>>((ref) async {
  ref.watch(budgetRefreshProvider);
  final dao = await ref.watch(budgetDaoProvider.future);
  return dao.getAll();
});
