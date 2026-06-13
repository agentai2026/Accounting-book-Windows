import 'dart:io';

import 'package:excel/excel.dart';
import 'package:ezbookkeeping_desktop/core/constants/transaction_import_columns.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/account_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/category_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/transaction_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/database_helper.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_exception.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/label_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';
import 'package:path/path.dart' as p;

class ExportService {
  ExportService({
    required TransactionDao transactionDao,
    required AccountDao accountDao,
    required CategoryDao categoryDao,
    required DatabaseHelper databaseHelper,
  })  : _transactionDao = transactionDao,
        _accountDao = accountDao,
        _categoryDao = categoryDao,
        _databaseHelper = databaseHelper;

  final TransactionDao _transactionDao;
  final AccountDao _accountDao;
  final CategoryDao _categoryDao;
  final DatabaseHelper _databaseHelper;

  Future<Result<String>> exportTransactionsCsv({
    required int bookId,
    required String savePath,
    String currencyCode = 'CNY',
  }) async {
    try {
      final transactions = await _transactionDao.search(
        TransactionQuery(bookId: bookId, limit: 100000),
      );
      final accounts = await _accountDao.getAll(bookId: bookId);
      final categories = await _categoryDao.getAll();
      final accountNames = {
        for (final account in accounts)
          if (account.id != null) account.id!: account.name,
      };
      final categoryNames = {
        for (final category in categories)
          if (category.id != null) category.id!: category.name,
      };

      final buffer = StringBuffer()
        ..writeln(TransactionImportColumns.headerLine);

      for (final tx in transactions) {
        final accountId = tx.type == TransactionType.expense
            ? tx.fromAccountId
            : tx.toAccountId;
        buffer.writeln(
          [
            AppDateUtils.formatDateTime(tx.date),
            transactionTypeLabel(tx.type),
            MoneyUtils.formatInputAmount(tx.amount),
            categoryNames[tx.categoryId] ?? '${tx.categoryId}',
            accountNames[accountId] ?? '',
            tx.payer ?? '',
            tx.description ?? '',
          ].map(_escapeCsvCell).join(','),
        );
      }

      await File(savePath).writeAsString('\uFEFF${buffer.toString()}');
      return Result.success(savePath);
    } catch (e, stack) {
      appLogger.e('导出 CSV 失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('导出 CSV 失败: $e', code: 'EXPORT_ERROR'),
      );
    }
  }

  Future<Result<String>> exportTransactionsExcel({
    required int bookId,
    required String savePath,
    String currencyCode = 'CNY',
  }) async {
    try {
      final transactions = await _transactionDao.search(
        TransactionQuery(bookId: bookId, limit: 100000),
      );
      final accounts = await _accountDao.getAll(bookId: bookId);
      final categories = await _categoryDao.getAll();
      final accountNames = {
        for (final account in accounts)
          if (account.id != null) account.id!: account.name,
      };
      final categoryNames = {
        for (final category in categories)
          if (category.id != null) category.id!: category.name,
      };

      final excel = Excel.createExcel();
      final sheet = excel['交易记录'];
      excel.delete('Sheet1');

      sheet.appendRow(
        TransactionImportColumns.headers
            .map((header) => TextCellValue(header))
            .toList(),
      );

      for (final tx in transactions) {
        final accountId = tx.type == TransactionType.expense
            ? tx.fromAccountId
            : tx.toAccountId;
        sheet.appendRow([
          TextCellValue(AppDateUtils.formatDateTime(tx.date)),
          TextCellValue(transactionTypeLabel(tx.type)),
          TextCellValue(MoneyUtils.formatInputAmount(tx.amount)),
          TextCellValue(categoryNames[tx.categoryId] ?? '${tx.categoryId}'),
          TextCellValue(accountNames[accountId] ?? ''),
          TextCellValue(tx.payer ?? ''),
          TextCellValue(tx.description ?? ''),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) {
        return Result.failure(
          const AppException('生成 Excel 失败', code: 'EXPORT_ERROR'),
        );
      }
      await File(savePath).writeAsBytes(bytes);
      return Result.success(savePath);
    } catch (e, stack) {
      appLogger.e('导出 Excel 失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('导出 Excel 失败: $e', code: 'EXPORT_ERROR'),
      );
    }
  }

  Future<Result<String>> exportDatabaseCopy(String savePath) async {
    try {
      final dbPath = await _databaseHelper.getDatabasePath();
      await File(dbPath).copy(savePath);
      return Result.success(savePath);
    } catch (e, stack) {
      appLogger.e('导出数据库失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('导出数据库失败: $e', code: 'EXPORT_ERROR'),
      );
    }
  }

  Future<Result<String>> importDatabaseCopy(String sourcePath) async {
    try {
      final dbPath = await _databaseHelper.getDatabasePath();
      await _databaseHelper.close();
      await File(sourcePath).copy(dbPath);
      return Result.success(dbPath);
    } catch (e, stack) {
      appLogger.e('导入数据库失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('导入数据库失败: $e', code: 'IMPORT_ERROR'),
      );
    }
  }

  String suggestExportFileName(String extension) {
    final stamp = AppDateUtils.formatDate(DateTime.now()).replaceAll('/', '');
    return 'ezbookkeeping_$stamp.$extension';
  }

  String joinExportPath(String directory, String fileName) {
    return p.join(directory, fileName);
  }

  static String _escapeCsvCell(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
