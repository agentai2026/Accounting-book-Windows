import 'package:ezbookkeeping_desktop/core/database/daos/budget_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/transaction_dao.dart';
import 'package:ezbookkeeping_desktop/core/models/budget.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_exception.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';
import 'package:uuid/uuid.dart';

class BudgetWithProgress {
  const BudgetWithProgress({
    required this.budget,
    required this.spentCents,
    required this.categoryName,
  });

  final Budget budget;
  final int spentCents;
  final String categoryName;

  double get rawProgress =>
      budget.amount > 0 ? spentCents / budget.amount : 0;

  double get progress => rawProgress.clamp(0.0, 1.0);

  bool get isOverBudget => spentCents > budget.amount;
}

class BudgetService {
  BudgetService(this._budgetDao, this._transactionDao);

  final BudgetDao _budgetDao;
  final TransactionDao _transactionDao;
  static const _uuid = Uuid();

  Future<Result<Budget>> createBudget({
    required int bookId,
    required int amountCents,
    required BudgetPeriodType periodType,
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (amountCents <= 0) {
      return Result.failure(
        const AppException('预算金额必须大于 0', code: 'INVALID_AMOUNT'),
      );
    }

    try {
      final now = DateTime.now();
      final budget = Budget(
        uuid: _uuid.v4(),
        bookId: bookId,
        categoryId: categoryId,
        amount: amountCents,
        periodType: periodType,
        startDate: startDate,
        endDate: endDate,
        createdAt: now,
        updatedAt: now,
      );
      final id = await _budgetDao.insert(budget);
      return Result.success(budget.copyWith(id: id));
    } catch (e, stack) {
      appLogger.e('创建预算失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('创建预算失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<Budget>> updateBudget({
    required Budget budget,
    required int amountCents,
    required BudgetPeriodType periodType,
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (amountCents <= 0) {
      return Result.failure(
        const AppException('预算金额必须大于 0', code: 'INVALID_AMOUNT'),
      );
    }

    try {
      final updated = budget.copyWith(
        amount: amountCents,
        periodType: periodType,
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
        updatedAt: DateTime.now(),
        clearCategoryId: categoryId == null,
      );
      await _budgetDao.update(updated);
      return Result.success(updated);
    } catch (e, stack) {
      appLogger.e('更新预算失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('更新预算失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<void>> deleteBudget(int id) async {
    try {
      await _budgetDao.softDelete(id, DateTime.now());
      return Result.success(null);
    } catch (e, stack) {
      appLogger.e('删除预算失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('删除预算失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<List<BudgetWithProgress>> getBudgetsWithProgress({
    required int bookId,
    required Map<int, String> categoryNames,
    DateTime? reference,
    int monthStartDay = 1,
  }) async {
    final now = reference ?? DateTime.now();
    final budgets = await _budgetDao.getAll(bookId: bookId);
    final results = <BudgetWithProgress>[];

    for (final budget in budgets) {
      final range = _resolveRange(budget, now, monthStartDay: monthStartDay);
      final spent = await _transactionDao.sumAmountByType(
        bookId: bookId,
        type: TransactionType.expense,
        start: range.start,
        end: range.end,
      );
      final categorySpent = budget.categoryId == null
          ? spent
          : await _sumCategoryExpense(
              bookId: bookId,
              categoryId: budget.categoryId!,
              start: range.start,
              end: range.end,
            );

      results.add(
        BudgetWithProgress(
          budget: budget,
          spentCents: categorySpent,
          categoryName: budget.categoryId == null
              ? '总预算'
              : (categoryNames[budget.categoryId] ?? '未知分类'),
        ),
      );
    }

    return results;
  }

  Future<int> _sumCategoryExpense({
    required int bookId,
    required int categoryId,
    required DateTime start,
    required DateTime end,
  }) async {
    final grouped = await _transactionDao.sumAmountGroupByCategory(
      bookId: bookId,
      type: TransactionType.expense,
      start: start,
      end: end,
    );
    return grouped[categoryId] ?? 0;
  }

  ({DateTime start, DateTime end}) _resolveRange(
    Budget budget,
    DateTime now, {
    int monthStartDay = 1,
  }) {
    return switch (budget.periodType) {
      BudgetPeriodType.monthly => (
          start: AppDateUtils.startOfBillingMonth(
            now,
            monthStartDay: monthStartDay,
          ),
          end: AppDateUtils.endOfBillingMonth(
            now,
            monthStartDay: monthStartDay,
          ),
        ),
      BudgetPeriodType.yearly => (
          start: AppDateUtils.startOfYear(now),
          end: AppDateUtils.endOfYear(now),
        ),
      BudgetPeriodType.custom => (
          start: AppDateUtils.startOfDay(
            budget.startDate ?? now,
          ),
          end: AppDateUtils.endOfDay(budget.endDate ?? now),
        ),
    };
  }
}
