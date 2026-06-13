import 'package:ezbookkeeping_desktop/core/database/daos/account_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/book_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/budget_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/category_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/loan_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/scheduled_transaction_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/tag_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/transaction_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/database_helper.dart';
import 'package:ezbookkeeping_desktop/core/services/account_service.dart';
import 'package:ezbookkeeping_desktop/core/services/backup_service.dart';
import 'package:ezbookkeeping_desktop/core/services/book_service.dart';
import 'package:ezbookkeeping_desktop/core/services/bookkeeping_service.dart';
import 'package:ezbookkeeping_desktop/core/services/budget_service.dart';
import 'package:ezbookkeeping_desktop/core/services/category_service.dart';
import 'package:ezbookkeeping_desktop/core/services/demo_transaction_seed_service.dart';
import 'package:ezbookkeeping_desktop/core/services/export_service.dart';
import 'package:ezbookkeeping_desktop/core/services/transaction_image_service.dart';
import 'package:ezbookkeeping_desktop/core/services/transaction_import_service.dart';
import 'package:ezbookkeeping_desktop/core/services/loan_service.dart';
import 'package:ezbookkeeping_desktop/core/services/reimbursement_service.dart';
import 'package:ezbookkeeping_desktop/core/services/scheduled_transaction_service.dart';
import 'package:ezbookkeeping_desktop/core/services/tag_service.dart';
import 'package:ezbookkeeping_desktop/core/database/database_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  return DatabaseHelper.instance.database;
});

final bookDaoProvider = FutureProvider<BookDao>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return BookDao(db);
});

final accountDaoProvider = FutureProvider<AccountDao>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return AccountDao(db);
});

final categoryDaoProvider = FutureProvider<CategoryDao>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return CategoryDao(db);
});

final transactionDaoProvider = FutureProvider<TransactionDao>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return TransactionDao(db);
});

final tagDaoProvider = FutureProvider<TagDao>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return TagDao(db);
});

final budgetDaoProvider = FutureProvider<BudgetDao>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return BudgetDao(db);
});

final loanDaoProvider = FutureProvider<LoanDao>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return LoanDao(db);
});

final scheduledTransactionDaoProvider =
    FutureProvider<ScheduledTransactionDao>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return ScheduledTransactionDao(db);
});

final bookkeepingServiceProvider = FutureProvider<BookkeepingService>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final transactionDao = await ref.watch(transactionDaoProvider.future);
  final accountDao = await ref.watch(accountDaoProvider.future);
  final categoryDao = await ref.watch(categoryDaoProvider.future);
  return BookkeepingService(
    database: db,
    transactionDao: transactionDao,
    accountDao: accountDao,
    categoryDao: categoryDao,
  );
});

final accountServiceProvider = FutureProvider<AccountService>((ref) async {
  final dao = await ref.watch(accountDaoProvider.future);
  return AccountService(dao);
});

final categoryServiceProvider = FutureProvider<CategoryService>((ref) async {
  final dao = await ref.watch(categoryDaoProvider.future);
  return CategoryService(dao);
});

final tagServiceProvider = FutureProvider<TagService>((ref) async {
  final dao = await ref.watch(tagDaoProvider.future);
  return TagService(dao);
});

final reimbursementServiceProvider =
    FutureProvider<ReimbursementService>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final transactionDao = await ref.watch(transactionDaoProvider.future);
  final tagDao = await ref.watch(tagDaoProvider.future);
  final tagService = await ref.watch(tagServiceProvider.future);
  return ReimbursementService(
    database: db,
    transactionDao: transactionDao,
    tagDao: tagDao,
    tagService: tagService,
  );
});

final bookServiceProvider = FutureProvider<BookService>((ref) async {
  final dao = await ref.watch(bookDaoProvider.future);
  return BookService(dao);
});

final budgetServiceProvider = FutureProvider<BudgetService>((ref) async {
  final budgetDao = await ref.watch(budgetDaoProvider.future);
  final transactionDao = await ref.watch(transactionDaoProvider.future);
  return BudgetService(budgetDao, transactionDao);
});

final loanServiceProvider = FutureProvider<LoanService>((ref) async {
  final dao = await ref.watch(loanDaoProvider.future);
  return LoanService(dao);
});

final scheduledTransactionServiceProvider =
    FutureProvider<ScheduledTransactionService>((ref) async {
  final scheduledDao = await ref.watch(scheduledTransactionDaoProvider.future);
  final transactionDao = await ref.watch(transactionDaoProvider.future);
  final bookkeeping = await ref.watch(bookkeepingServiceProvider.future);
  return ScheduledTransactionService(
    scheduledDao,
    transactionDao,
    bookkeeping,
  );
});

final exportServiceProvider = FutureProvider<ExportService>((ref) async {
  final transactionDao = await ref.watch(transactionDaoProvider.future);
  final accountDao = await ref.watch(accountDaoProvider.future);
  final categoryDao = await ref.watch(categoryDaoProvider.future);
  return ExportService(
    transactionDao: transactionDao,
    accountDao: accountDao,
    categoryDao: categoryDao,
    databaseHelper: DatabaseHelper.instance,
  );
});

final transactionImageServiceProvider =
    Provider<TransactionImageService>((ref) {
  return TransactionImageService();
});

final transactionImportServiceProvider =
    FutureProvider<TransactionImportService>((ref) async {
  return TransactionImportService(
    bookkeeping: await ref.watch(bookkeepingServiceProvider.future),
    accountDao: await ref.watch(accountDaoProvider.future),
    categoryDao: await ref.watch(categoryDaoProvider.future),
    exportService: await ref.watch(exportServiceProvider.future),
  );
});

final backupServiceProvider = FutureProvider<BackupService>((ref) async {
  return BackupService(DatabaseHelper.instance);
});

final demoTransactionSeedServiceProvider =
    FutureProvider<DemoTransactionSeedService>((ref) async {
  final bookkeeping = await ref.watch(bookkeepingServiceProvider.future);
  final accountService = await ref.watch(accountServiceProvider.future);
  final categoryService = await ref.watch(categoryServiceProvider.future);
  final tagService = await ref.watch(tagServiceProvider.future);
  final bookDao = await ref.watch(bookDaoProvider.future);
  final accountDao = await ref.watch(accountDaoProvider.future);
  final categoryDao = await ref.watch(categoryDaoProvider.future);
  final tagDao = await ref.watch(tagDaoProvider.future);
  return DemoTransactionSeedService(
    database: await ref.watch(databaseProvider.future),
    bookkeepingService: bookkeeping,
    accountService: accountService,
    categoryService: categoryService,
    tagService: tagService,
    bookDao: bookDao,
    accountDao: accountDao,
    categoryDao: categoryDao,
    tagDao: tagDao,
  );
});
