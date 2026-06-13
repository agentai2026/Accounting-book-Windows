import 'package:ezbookkeeping_desktop/core/database/database_helper.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/account_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/loan_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/reimbursement_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/scheduled_transaction_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/tag_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 外部替换数据库文件后，关闭连接并刷新全部数据 Provider。
Future<void> reloadDatabaseLayer(WidgetRef ref) async {
  await DatabaseHelper.instance.close();
  ref.invalidate(databaseProvider);
  ref.read(bookRefreshProvider.notifier).state++;
  ref.read(transactionRefreshProvider.notifier).state++;
  ref.read(budgetRefreshProvider.notifier).state++;
  ref.read(loanRefreshProvider.notifier).state++;
  ref.read(scheduledTransactionRefreshProvider.notifier).state++;
  ref.read(reimbursementRefreshProvider.notifier).state++;
  refreshAccounts(ref);
  refreshCategories(ref);
  refreshBooks(ref);
  refreshTags(ref);
  refreshLoans(ref);
  await ref.read(databaseProvider.future);
}
