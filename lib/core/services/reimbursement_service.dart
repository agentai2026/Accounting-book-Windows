import 'package:ezbookkeeping_desktop/core/constants/transaction_flag_tags.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/tag_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/transaction_dao.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/services/tag_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_exception.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';
import 'package:sqflite/sqflite.dart';

class ReimbursementSummary {
  const ReimbursementSummary({
    required this.pendingCount,
    required this.pendingCents,
    required this.reimbursedCount,
    required this.reimbursedCents,
  });

  final int pendingCount;
  final int pendingCents;
  final int reimbursedCount;
  final int reimbursedCents;
}

class ReimbursementService {
  ReimbursementService({
    required Database database,
    required TransactionDao transactionDao,
    required TagDao tagDao,
    required TagService tagService,
  })  : _db = database,
        _transactionDao = transactionDao,
        _tagDao = tagDao,
        _tagService = tagService;

  final Database _db;
  final TransactionDao _transactionDao;
  final TagDao _tagDao;
  final TagService _tagService;

  Future<Result<ReimbursementSummary>> getSummary({int? bookId}) async {
    try {
      final pending = await _transactionDao.sumReimbursementStatistics(
        bookId: bookId,
        status: ReimbursementStatus.pending,
      );
      final reimbursed = await _transactionDao.sumReimbursementStatistics(
        bookId: bookId,
        status: ReimbursementStatus.reimbursed,
      );
      return Result.success(
        ReimbursementSummary(
          pendingCount: pending.count,
          pendingCents: pending.amountCents,
          reimbursedCount: reimbursed.count,
          reimbursedCents: reimbursed.amountCents,
        ),
      );
    } catch (e, stack) {
      appLogger.e('加载报销汇总失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('加载报销汇总失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<void>> markReimbursed(int transactionId) async {
    try {
      final transaction = await _transactionDao.getById(transactionId);
      if (transaction == null) {
        return Result.failure(
          const AppException('账单不存在', code: 'NOT_FOUND'),
        );
      }
      if (!transaction.isReimbursable) {
        return Result.failure(
          const AppException('该账单未标记为可报销', code: 'NOT_REIMBURSABLE'),
        );
      }
      if (transaction.type != TransactionType.expense) {
        return Result.failure(
          const AppException('仅支出账单可标记报销', code: 'INVALID_TYPE'),
        );
      }

      final tagIdsResult =
          await _tagService.resolveTagIds([TransactionFlagTags.reimbursed]);
      final tagIds = tagIdsResult.when(
        success: (ids) => ids,
        failure: (error) => throw error,
      );
      if (tagIds.isEmpty) {
        return Result.failure(
          const AppException('创建报销标签失败', code: 'TAG_ERROR'),
        );
      }

      final now = DateTime.now();
      await _db.transaction((txn) async {
        await _tagDao.linkTagToTransaction(
          transactionId,
          tagIds.first,
          executor: txn,
        );
        await txn.update(
          'transactions',
          {'updated_at': now.millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [transactionId],
        );
      });

      return Result.success(null);
    } on AppException catch (error) {
      return Result.failure(error);
    } catch (e, stack) {
      appLogger.e('标记已报销失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('标记已报销失败: $e', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<void>> unmarkReimbursed(int transactionId) async {
    try {
      final transaction = await _transactionDao.getById(transactionId);
      if (transaction == null) {
        return Result.failure(
          const AppException('账单不存在', code: 'NOT_FOUND'),
        );
      }

      final tag = await _tagDao.findByName(TransactionFlagTags.reimbursed);
      if (tag?.id == null) {
        return Result.success(null);
      }

      final now = DateTime.now();
      await _db.transaction((txn) async {
        await _tagDao.unlinkTagFromTransaction(
          transactionId,
          tag!.id!,
          executor: txn,
        );
        await txn.update(
          'transactions',
          {'updated_at': now.millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [transactionId],
        );
      });

      return Result.success(null);
    } catch (e, stack) {
      appLogger.e('撤销已报销失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('撤销已报销失败: $e', code: 'DB_ERROR'),
      );
    }
  }
}
