import 'package:ezbookkeeping_desktop/core/database/daos/account_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/category_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/transaction_dao.dart';
import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/transaction.dart' as models;
import 'package:ezbookkeeping_desktop/core/services/alipay_transfer_account_resolver.dart';
import 'package:ezbookkeeping_desktop/core/services/create_transaction_input.dart';
import 'package:ezbookkeeping_desktop/core/services/import_payment_account_resolver.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_exception.dart';
import 'package:ezbookkeeping_desktop/core/utils/import_source_metadata.dart';
import 'package:ezbookkeeping_desktop/core/utils/transaction_display_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class BookkeepingService {
  BookkeepingService({
    required Database database,
    required TransactionDao transactionDao,
    required AccountDao accountDao,
    required CategoryDao categoryDao,
  })  : _db = database,
        _transactionDao = transactionDao,
        _accountDao = accountDao,
        _categoryDao = categoryDao;

  final Database _db;
  final TransactionDao _transactionDao;
  final AccountDao _accountDao;
  final CategoryDao _categoryDao;
  static const _uuid = Uuid();

  Future<Result<List<models.Transaction>>> getTransactions({
    int? bookId,
    int limit = 50,
    int offset = 0,
    TransactionType? type,
    String? keyword,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final list = await _transactionDao.search(
        TransactionQuery(
          bookId: bookId,
          limit: limit,
          offset: offset,
          type: type,
          keyword: keyword,
          startDate: startDate,
          endDate: endDate,
        ),
      );
      return Result.success(list);
    } catch (e, stack) {
      appLogger.e('获取账单失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('获取账单失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<List<models.Transaction>>> findSimilarTransactions({
    required int bookId,
    required int amountInCents,
    required int categoryId,
    required DateTime date,
    int withinDays = 3,
  }) async {
    try {
      final start = AppDateUtils.startOfDay(
        date.subtract(Duration(days: withinDays)),
      );
      final end = AppDateUtils.endOfDay(
        date.add(Duration(days: withinDays)),
      );
      final list = await _transactionDao.search(
        TransactionQuery(
          bookId: bookId,
          startDate: start,
          endDate: end,
          limit: 50,
        ),
      );
      final matches = list
          .where(
            (t) => t.amount == amountInCents && t.categoryId == categoryId,
          )
          .toList();
      return Result.success(matches);
    } catch (e, stack) {
      appLogger.e('查找相似账单失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('查找相似账单失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<int>> getTransactionCount({
    int? bookId,
    TransactionType? type,
    String? keyword,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final count = await _transactionDao.count(
        bookId: bookId,
        type: type,
        keyword: keyword,
        startDate: startDate,
        endDate: endDate,
      );
      return Result.success(count);
    } catch (e, stack) {
      appLogger.e('统计账单数量失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('统计账单数量失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<int>> getTodayNetBalance(int bookId) async {
    try {
      final now = DateTime.now();
      final start = AppDateUtils.startOfDay(now);
      final end = AppDateUtils.endOfDay(now);
      final income = await _transactionDao.sumAmountByType(
        bookId: bookId,
        type: TransactionType.income,
        start: start,
        end: end,
      );
      final expense = await _transactionDao.sumAmountByType(
        bookId: bookId,
        type: TransactionType.expense,
        start: start,
        end: end,
      );
      return Result.success(income - expense);
    } catch (e, stack) {
      appLogger.e('计算今日结余失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('计算今日结余失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<models.Transaction>> createTransaction(
    CreateTransactionInput input,
  ) async {
    final validation = _validateInput(input);
    if (validation != null) {
      return Result.failure(validation);
    }

    try {
      final now = DateTime.now();
      final transaction = models.Transaction(
        uuid: _uuid.v4(),
        bookId: input.bookId,
        type: input.type,
        amount: input.amountInCents,
        categoryId: input.categoryId,
        fromAccountId: input.fromAccountId,
        toAccountId: input.toAccountId,
        date: input.date,
        timezoneUtcOffset: input.timezoneUtcOffset ??
            DateTime.now().timeZoneOffset.inMinutes,
        comment: _trimOrNull(input.comment),
        payer: _trimOrNull(input.payer),
        description: _trimOrNull(input.description),
        images: input.images.isEmpty ? null : input.images,
        isReimbursable: input.isReimbursable,
        isScheduled: input.isScheduled,
        scheduledTransactionId: input.scheduledTransactionId,
        createdAt: now,
        updatedAt: now,
      );

      late models.Transaction saved;
      await _db.transaction((txn) async {
        final id = await txn.insert('transactions', transaction.toMap());
        await _applyBalanceChange(txn, transaction, reverse: false);
        if (input.tagIds.isNotEmpty) {
          for (final tagId in input.tagIds) {
            await txn.insert('transaction_tags', {
              'transaction_id': id,
              'tag_id': tagId,
            });
          }
        }
        saved = transaction.copyWith(id: id);
      });

      return Result.success(saved);
    } catch (e, stack) {
      appLogger.e('创建账单失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('创建账单失败: $e', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<models.Transaction>> updateTransaction(
    UpdateTransactionInput input,
  ) async {
    final existing = await _transactionDao.getById(input.transactionId);
    if (existing == null) {
      return Result.failure(
        const AppException('账单不存在', code: 'NOT_FOUND'),
      );
    }

    final validation = _validateInput(
      CreateTransactionInput(
        bookId: existing.bookId,
        type: input.type,
        amountInCents: input.amountInCents,
        categoryId: input.categoryId,
        fromAccountId: input.fromAccountId,
        toAccountId: input.toAccountId,
        date: input.date,
        timezoneUtcOffset: input.timezoneUtcOffset,
        comment: input.comment,
        payer: input.payer,
        description: input.description,
        tagIds: input.tagIds,
      ),
    );
    if (validation != null) {
      return Result.failure(validation);
    }

    try {
      final now = DateTime.now();
      final updated = existing.copyWith(
        type: input.type,
        amount: input.amountInCents,
        categoryId: input.categoryId,
        fromAccountId: input.fromAccountId,
        toAccountId: input.toAccountId,
        date: input.date,
        timezoneUtcOffset: input.timezoneUtcOffset ??
            DateTime.now().timeZoneOffset.inMinutes,
        comment: _trimOrNull(input.comment),
        payer: _trimOrNull(input.payer),
        description: _trimOrNull(input.description),
        isReimbursable: input.isReimbursable ?? existing.isReimbursable,
        updatedAt: now,
      );

      await _db.transaction((txn) async {
        await _applyBalanceChange(txn, existing, reverse: true);
        await txn.update(
          'transactions',
          updated.toMap(),
          where: 'id = ?',
          whereArgs: [input.transactionId],
        );
        await _applyBalanceChange(txn, updated, reverse: false);
        await txn.delete(
          'transaction_tags',
          where: 'transaction_id = ?',
          whereArgs: [input.transactionId],
        );
        for (final tagId in input.tagIds) {
          await txn.insert('transaction_tags', {
            'transaction_id': input.transactionId,
            'tag_id': tagId,
          });
        }
      });

      return Result.success(updated);
    } catch (e, stack) {
      appLogger.e('更新账单失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('更新账单失败: $e', code: 'DB_ERROR'),
      );
    }
  }

  /// 仅更新账单标签（保留其余字段不变）
  Future<Result<void>> updateTransactionTags({
    required int transactionId,
    required List<int> tagIds,
  }) async {
    final existing = await _transactionDao.getById(transactionId);
    if (existing == null) {
      return Result.failure(
        const AppException('账单不存在', code: 'NOT_FOUND'),
      );
    }

    try {
      final now = DateTime.now();
      await _db.transaction((txn) async {
        await txn.update(
          'transactions',
          {'updated_at': now.millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [transactionId],
        );
        await txn.delete(
          'transaction_tags',
          where: 'transaction_id = ?',
          whereArgs: [transactionId],
        );
        for (final tagId in tagIds) {
          await txn.insert('transaction_tags', {
            'transaction_id': transactionId,
            'tag_id': tagId,
          });
        }
      });
      return Result.success(null);
    } catch (e, stack) {
      appLogger.e('更新账单标签失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('更新账单标签失败: $e', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<void>> deleteTransaction(int id) async {
    try {
      final existing = await _transactionDao.getById(id);
      if (existing == null) {
        return Result.failure(
          const AppException('账单不存在', code: 'NOT_FOUND'),
        );
      }

      final now = DateTime.now();
      await _db.transaction((txn) async {
        await txn.update(
          'transactions',
          {
            'deleted_at': now.millisecondsSinceEpoch,
            'updated_at': now.millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        await txn.delete(
          'transaction_tags',
          where: 'transaction_id = ?',
          whereArgs: [id],
        );
        await _applyBalanceChange(txn, existing, reverse: true);
      });

      return Result.success(null);
    } catch (e, stack) {
      appLogger.e('删除账单失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('删除账单失败', code: 'DB_ERROR'),
      );
    }
  }

  /// 删除全部未软删的交易，并回滚对应账户余额。
  Future<Result<int>> deleteAllTransactions({int? bookId}) async {
    try {
      final all = await _transactionDao.listAllActive(bookId: bookId);
      if (all.isEmpty) {
        return Result.success(0);
      }

      final now = DateTime.now();
      await _db.transaction((txn) async {
        for (final transaction in all) {
          if (transaction.id == null) continue;
          await _applyBalanceChange(txn, transaction, reverse: true);
          await txn.update(
            'transactions',
            {
              'deleted_at': now.millisecondsSinceEpoch,
              'updated_at': now.millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [transaction.id],
          );
          await txn.delete(
            'transaction_tags',
            where: 'transaction_id = ?',
            whereArgs: [transaction.id],
          );
        }
      });

      return Result.success(all.length);
    } catch (e, stack) {
      appLogger.e('清空交易失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('清空交易失败: $e', code: 'DB_ERROR'),
      );
    }
  }

  Future<Category?> findTransferCategory() async {
    final categories = await _categoryDao.getAll(type: CategoryType.transfer);
    for (final category in categories) {
      if (category.parentId != null) return category;
    }
    return categories.isEmpty ? null : categories.first;
  }

  AppException? _validateInput(CreateTransactionInput input) {
    if (input.amountInCents < 0) {
      return const AppException('金额不能为负数', code: 'INVALID_AMOUNT');
    }

    switch (input.type) {
      case TransactionType.expense:
        if (input.fromAccountId == null) {
          return const AppException('请选择支出账户', code: 'INVALID_ACCOUNT');
        }
      case TransactionType.income:
        if (input.toAccountId == null) {
          return const AppException('请选择收入账户', code: 'INVALID_ACCOUNT');
        }
      case TransactionType.transfer:
        if (input.fromAccountId == null || input.toAccountId == null) {
          return const AppException('请选择转出和转入账户', code: 'INVALID_ACCOUNT');
        }
        if (input.fromAccountId == input.toAccountId) {
          return const AppException('转出和转入账户不能相同', code: 'INVALID_ACCOUNT');
        }
    }
    return null;
  }

  Future<void> _applyBalanceChange(
    DatabaseExecutor txn,
    models.Transaction transaction, {
    required bool reverse,
  }) async {
    final factor = reverse ? -1 : 1;

    switch (transaction.type) {
      case TransactionType.expense:
        await _adjustAccountBalance(
          txn,
          transaction.fromAccountId!,
          -transaction.amount * factor,
        );
      case TransactionType.income:
        await _adjustAccountBalance(
          txn,
          transaction.toAccountId!,
          transaction.amount * factor,
        );
      case TransactionType.transfer:
        await _adjustAccountBalance(
          txn,
          transaction.fromAccountId!,
          -transaction.amount * factor,
        );
        await _adjustAccountBalance(
          txn,
          transaction.toAccountId!,
          transaction.amount * factor,
        );
    }
  }

  Future<void> _adjustAccountBalance(
    DatabaseExecutor txn,
    int accountId,
    int delta,
  ) async {
    final rows = await txn.query(
      'accounts',
      columns: ['balance'],
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [accountId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw AppException('账户不存在: $accountId', code: 'NOT_FOUND');
    }

    final current = rows.first['balance'] as int? ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    await txn.update(
      'accounts',
      {
        'balance': current + delta,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  /// 根据导入元数据或历史字段（payer / 备注）修正账单账户归属
  Future<Result<int>> repairImportedTransactionAccounts({
    required int bookId,
  }) async {
    try {
      final accounts = await _accountDao.getAll(bookId: bookId);
      final categories = await _categoryDao.getAll();
      final categoryNames = {
        for (final category in categories)
          if (category.id != null) category.id!: category.name,
      };
      final transactions =
          await _transactionDao.listAllActive(bookId: bookId);

      var repaired = 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      await _db.transaction((txn) async {
        for (final transaction in transactions) {
          final hints = _resolveRepairHints(transaction, categoryNames);
          if (hints == null) continue;

          final categoryName =
              hints.categoryName ?? categoryNames[transaction.categoryId];
          final paymentMethod = hints.paymentMethod;
          final remark = hints.remark;

          var changed = false;
          final updates = <String, Object>{'updated_at': now};

          switch (transaction.type) {
            case TransactionType.expense:
              final resolved = ImportPaymentAccountResolver.resolveAccountId(
                accounts: accounts,
                paymentMethod: paymentMethod,
                importSource: hints.importSource,
                categoryName: categoryName,
                remark: remark,
              );
              if (resolved != null && resolved != transaction.fromAccountId) {
                updates['from_account_id'] = resolved;
                changed = true;
              }
            case TransactionType.income:
              final resolved = ImportPaymentAccountResolver.resolveAccountId(
                accounts: accounts,
                paymentMethod: paymentMethod,
                importSource: hints.importSource,
                categoryName: categoryName,
                remark: remark,
              );
              if (resolved != null && resolved != transaction.toAccountId) {
                updates['to_account_id'] = resolved;
                changed = true;
              }
            case TransactionType.transfer:
              final hintsTransfer = AlipayTransferAccountResolver.resolve(
                paymentMethod: paymentMethod,
                categoryName: categoryName,
                remark: remark,
              );
              final fromId = ImportPaymentAccountResolver.resolveAccountId(
                accounts: accounts,
                paymentMethod: hintsTransfer.from,
                importSource: hints.importSource,
                categoryName: categoryName,
                remark: remark,
              );
              final toId = ImportPaymentAccountResolver.resolveAccountId(
                accounts: accounts,
                paymentMethod: hintsTransfer.to,
                importSource: hints.importSource,
                categoryName: categoryName,
                remark: remark,
              );
              if (fromId != null && fromId != transaction.fromAccountId) {
                updates['from_account_id'] = fromId;
                changed = true;
              }
              if (toId != null && toId != transaction.toAccountId) {
                updates['to_account_id'] = toId;
                changed = true;
              }
          }

          if (hints.backfillMetadata && changed) {
            final metadata = ImportSourceMetadata.encode(
              recordVia: TransactionRecordVia.import,
              categoryName: categoryName,
              paymentMethod: paymentMethod,
              importSource: hints.importSource,
            );
            if (metadata.isNotEmpty) {
              updates['comment'] = ImportSourceMetadata.mergeComment(
                existingComment: transaction.comment,
                metadata: metadata,
              );
            }
          }

          if (changed) {
            await txn.update(
              'transactions',
              updates,
              where: 'id = ?',
              whereArgs: [transaction.id],
            );
            repaired++;
          }
        }
      });

      return Result.success(repaired);
    } catch (e, stack) {
      appLogger.e('修复导入账户归属失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('修复导入账户归属失败: $e', code: 'DB_ERROR'),
      );
    }
  }

  /// 修正导入账户归属后重算余额（一键修复导入错账）
  Future<Result<({int repaired, int accountCount})>>
      repairAndRecalculateAccountBalances({
    required int bookId,
  }) async {
    final repair = await repairImportedTransactionAccounts(bookId: bookId);
    return repair.when(
      success: (repaired) async {
        final recalc = await recalculateAccountBalances(bookId: bookId);
        return recalc.when(
          success: (accountCount) => Result.success(
            (repaired: repaired, accountCount: accountCount),
          ),
          failure: (error) => Result.failure(error),
        );
      },
      failure: (error) => Result.failure(error),
    );
  }

  /// 按全部账单重算账户余额（修复导入错账、历史数据偏差）
  Future<Result<int>> recalculateAccountBalances({required int bookId}) async {
    try {
      final accounts = await _accountDao.getAll(bookId: bookId);
      final transactions =
          await _transactionDao.listAllActive(bookId: bookId);

      final balances = <int, int>{
        for (final account in accounts)
          if (account.id != null) account.id!: 0,
      };

      for (final transaction in transactions) {
        switch (transaction.type) {
          case TransactionType.expense:
            final id = transaction.fromAccountId;
            if (id != null) {
              balances[id] = (balances[id] ?? 0) - transaction.amount;
            }
          case TransactionType.income:
            final id = transaction.toAccountId;
            if (id != null) {
              balances[id] = (balances[id] ?? 0) + transaction.amount;
            }
          case TransactionType.transfer:
            final fromId = transaction.fromAccountId;
            final toId = transaction.toAccountId;
            if (fromId != null) {
              balances[fromId] = (balances[fromId] ?? 0) - transaction.amount;
            }
            if (toId != null) {
              balances[toId] = (balances[toId] ?? 0) + transaction.amount;
            }
        }
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.transaction((txn) async {
        for (final account in accounts) {
          final id = account.id;
          if (id == null) continue;
          await txn.update(
            'accounts',
            {
              'balance': balances[id] ?? 0,
              'updated_at': now,
            },
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      });

      return Result.success(accounts.length);
    } catch (e, stack) {
      appLogger.e('重算账户余额失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('重算账户余额失败: $e', code: 'DB_ERROR'),
      );
    }
  }
}

class _RepairHints {
  const _RepairHints({
    required this.paymentMethod,
    required this.importSource,
    required this.categoryName,
    required this.remark,
    this.backfillMetadata = false,
  });

  final String? paymentMethod;
  final String? importSource;
  final String? categoryName;
  final String? remark;
  final bool backfillMetadata;
}

_RepairHints? _resolveRepairHints(
  models.Transaction transaction,
  Map<int, String> categoryNames,
) {
  final meta = ImportSourceMetadata.parse(transaction.comment);
  final categoryName =
      meta?.categoryName ?? categoryNames[transaction.categoryId];
  final remark = transaction.description ??
      ImportSourceMetadata.stripMetadata(transaction.comment);

  if (meta != null) {
    return _RepairHints(
      paymentMethod: meta.paymentMethod ?? transaction.payer,
      importSource: meta.importSource,
      categoryName: categoryName,
      remark: remark,
    );
  }

  final payer = transaction.payer?.trim();
  final desc = transaction.description?.trim();
  final comment = ImportSourceMetadata.stripMetadata(transaction.comment)?.trim();

  var paymentMethod = (payer != null && payer.isNotEmpty) ? payer : null;
  paymentMethod ??= _guessPaymentMethodFromText(desc);
  paymentMethod ??= _guessPaymentMethodFromText(comment);

  final blob = [
    paymentMethod,
    categoryName,
    desc,
    comment,
  ].whereType<String>().join('');
  final importSource = TransactionDisplayUtils.inferImportSourceFromText(blob);

  if ((paymentMethod == null || paymentMethod.isEmpty) &&
      importSource == null) {
    return null;
  }

  return _RepairHints(
    paymentMethod: paymentMethod,
    importSource: importSource,
    categoryName: categoryName,
    remark: remark ?? desc ?? comment,
    backfillMetadata: true,
  );
}

String? _guessPaymentMethodFromText(String? text) {
  if (text == null || text.trim().isEmpty) return null;
  const keywords = [
    '花呗',
    '借呗',
    '余额宝',
    '余利宝',
    '微信零钱',
    '零钱通',
    '零钱',
    '储蓄卡',
    '借记卡',
    '信用卡',
    '银行卡',
    '云闪付',
    '银联',
    '支付宝',
    '微信',
    '现金',
  ];
  final normalized = text.replaceAll(RegExp(r'\s+'), '');
  for (final keyword in keywords) {
    if (normalized.contains(keyword)) return text.trim();
  }
  return null;
}
