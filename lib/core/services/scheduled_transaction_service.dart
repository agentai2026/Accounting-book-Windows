import 'package:ezbookkeeping_desktop/core/database/daos/scheduled_transaction_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/transaction_dao.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/scheduled_transaction.dart';
import 'package:ezbookkeeping_desktop/core/models/transaction.dart' as models;
import 'package:ezbookkeeping_desktop/core/services/bookkeeping_service.dart';
import 'package:ezbookkeeping_desktop/core/services/create_transaction_input.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_exception.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';
import 'package:ezbookkeeping_desktop/core/utils/scheduled_run_calculator.dart';
import 'package:uuid/uuid.dart';

class ScheduledTransactionInput {
  const ScheduledTransactionInput({
    required this.bookId,
    required this.type,
    required this.amountInCents,
    required this.categoryId,
    this.fromAccountId,
    this.toAccountId,
    this.description,
    this.comment,
    this.location,
    this.isReimbursable = false,
    required this.frequency,
    this.intervalCount = 1,
    this.dayOfMonth,
    this.weekday,
    required this.startDate,
    this.endDate,
  });

  final int bookId;
  final TransactionType type;
  final int amountInCents;
  final int categoryId;
  final int? fromAccountId;
  final int? toAccountId;
  final String? description;
  final String? comment;
  final String? location;
  final bool isReimbursable;
  final ScheduledFrequency frequency;
  final int intervalCount;
  final int? dayOfMonth;
  final int? weekday;
  final DateTime startDate;
  final DateTime? endDate;
}

class ScheduledTransactionService {
  ScheduledTransactionService(
    this._scheduledDao,
    this._transactionDao,
    this._bookkeepingService,
  );

  final ScheduledTransactionDao _scheduledDao;
  final TransactionDao _transactionDao;
  final BookkeepingService _bookkeepingService;
  static const _uuid = Uuid();

  Future<Result<ScheduledTransaction>> create(
    ScheduledTransactionInput input,
  ) async {
    final validation = _validate(input);
    if (validation != null) return Result.failure(validation);

    try {
      final now = DateTime.now();
      final nextRun = ScheduledRunCalculator.resolveInitialNextRun(
        frequency: input.frequency,
        intervalCount: input.intervalCount,
        startDate: input.startDate,
        dayOfMonth: input.dayOfMonth,
        weekday: input.weekday,
      );

      final item = ScheduledTransaction(
        uuid: _uuid.v4(),
        bookId: input.bookId,
        type: input.type,
        amount: input.amountInCents,
        categoryId: input.categoryId,
        fromAccountId: input.fromAccountId,
        toAccountId: input.toAccountId,
        description: _trimOrNull(input.description),
        comment: _trimOrNull(input.comment),
        location: _trimOrNull(input.location),
        isReimbursable: input.isReimbursable,
        frequency: input.frequency,
        intervalCount: input.intervalCount,
        dayOfMonth: input.dayOfMonth,
        weekday: input.weekday,
        startDate: AppDateUtils.startOfDay(input.startDate),
        endDate: input.endDate == null
            ? null
            : AppDateUtils.endOfDay(input.endDate!),
        nextRunAt: nextRun,
        createdAt: now,
        updatedAt: now,
      );

      final id = await _scheduledDao.insert(item);
      return Result.success(item.copyWith(id: id));
    } catch (e, stack) {
      appLogger.e('创建周期记账失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('创建周期记账失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<ScheduledTransaction>> update({
    required ScheduledTransaction existing,
    required ScheduledTransactionInput input,
  }) async {
    final validation = _validate(input);
    if (validation != null) return Result.failure(validation);

    try {
      final now = DateTime.now();
      final nextRun = ScheduledRunCalculator.resolveInitialNextRun(
        frequency: input.frequency,
        intervalCount: input.intervalCount,
        startDate: input.startDate,
        dayOfMonth: input.dayOfMonth,
        weekday: input.weekday,
      );

      final updated = existing.copyWith(
        bookId: input.bookId,
        type: input.type,
        amount: input.amountInCents,
        categoryId: input.categoryId,
        fromAccountId: input.fromAccountId,
        toAccountId: input.toAccountId,
        clearFromAccount: input.fromAccountId == null,
        clearToAccount: input.toAccountId == null,
        description: _trimOrNull(input.description),
        comment: _trimOrNull(input.comment),
        location: _trimOrNull(input.location),
        isReimbursable: input.isReimbursable,
        frequency: input.frequency,
        intervalCount: input.intervalCount,
        dayOfMonth: input.dayOfMonth,
        weekday: input.weekday,
        startDate: AppDateUtils.startOfDay(input.startDate),
        endDate: input.endDate == null
            ? null
            : AppDateUtils.endOfDay(input.endDate!),
        clearEndDate: input.endDate == null,
        nextRunAt: nextRun,
        updatedAt: now,
      );

      await _scheduledDao.update(updated);
      return Result.success(updated);
    } catch (e, stack) {
      appLogger.e('更新周期记账失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('更新周期记账失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<ScheduledTransaction>> setPaused(
    ScheduledTransaction item,
    bool paused,
  ) async {
    try {
      final updated = item.copyWith(
        isPaused: paused,
        updatedAt: DateTime.now(),
      );
      await _scheduledDao.update(updated);
      return Result.success(updated);
    } catch (e, stack) {
      appLogger.e('更新周期记账状态失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('更新周期记账状态失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<void>> delete(int id) async {
    try {
      await _scheduledDao.softDelete(id, DateTime.now());
      return Result.success(null);
    } catch (e, stack) {
      appLogger.e('删除周期记账失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('删除周期记账失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<int> countDue({DateTime? now}) async {
    final due = await _scheduledDao.getDueBefore(now ?? DateTime.now());
    return due.length;
  }

  Future<Result<int>> executeDue({DateTime? now}) async {
    final due = await _scheduledDao.getDueBefore(now ?? DateTime.now());
    var count = 0;
    for (final item in due) {
      if (item.id == null) continue;
      final result = await executeOne(item.id!, now: now);
      result.when(
        success: (_) => count++,
        failure: (_) {},
      );
    }
    return Result.success(count);
  }

  Future<Result<models.Transaction?>> executeOne(
    int scheduledId, {
    DateTime? now,
    bool force = false,
  }) async {
    final item = await _scheduledDao.getById(scheduledId);
    if (item == null) {
      return Result.failure(
        const AppException('周期记账不存在', code: 'NOT_FOUND'),
      );
    }
    if (item.isPaused && !force) {
      return Result.failure(
        const AppException('周期记账已暂停', code: 'PAUSED'),
      );
    }

    final runAt = force
        ? AppDateUtils.startOfDay(now ?? DateTime.now())
        : AppDateUtils.startOfDay(item.nextRunAt);

    if (!force && runAt.isAfter(AppDateUtils.endOfDay(DateTime.now()))) {
      return Result.failure(
        const AppException('尚未到执行时间', code: 'NOT_DUE'),
      );
    }

    if (item.endDate != null && runAt.isAfter(item.endDate!)) {
      await setPaused(item, true);
      return Result.failure(
        const AppException('周期记账已到期', code: 'EXPIRED'),
      );
    }

    if (item.id != null &&
        await _transactionDao.existsForScheduledOnDay(item.id!, runAt)) {
      if (!force) {
        await _advanceSchedule(item, runAt);
      }
      return Result.failure(
        const AppException('该日已入账', code: 'ALREADY_RUN'),
      );
    }

    final createResult = await _bookkeepingService.createTransaction(
      CreateTransactionInput(
        bookId: item.bookId,
        type: item.type,
        amountInCents: item.amount,
        categoryId: item.categoryId,
        fromAccountId: item.fromAccountId,
        toAccountId: item.toAccountId,
        date: runAt,
        comment: item.comment,
        description: item.description,
        isReimbursable: item.isReimbursable,
        isScheduled: true,
        scheduledTransactionId: item.id,
      ),
    );

    return createResult.when(
      success: (transaction) async {
        await _advanceSchedule(item, runAt);
        return Result.success(transaction);
      },
      failure: (error) => Result.failure(error),
    );
  }

  Future<void> _advanceSchedule(
    ScheduledTransaction item,
    DateTime runAt,
  ) async {
    var next = ScheduledRunCalculator.advanceAfterRun(
      lastRunAt: runAt,
      frequency: item.frequency,
      intervalCount: item.intervalCount,
      dayOfMonth: item.dayOfMonth,
      weekday: item.weekday,
    );

    var paused = item.isPaused;
    if (item.endDate != null && next.isAfter(item.endDate!)) {
      paused = true;
    }

    final updated = item.copyWith(
      lastRunAt: runAt,
      nextRunAt: next,
      isPaused: paused,
      updatedAt: DateTime.now(),
    );
    await _scheduledDao.update(updated);
  }

  AppException? _validate(ScheduledTransactionInput input) {
    if (input.amountInCents <= 0) {
      return const AppException('金额必须大于 0', code: 'INVALID_AMOUNT');
    }
    if (input.intervalCount < 1) {
      return const AppException('间隔必须大于 0', code: 'INVALID_INTERVAL');
    }
    if (input.frequency == ScheduledFrequency.monthly &&
        input.dayOfMonth == null) {
      return const AppException('请选择每月执行日', code: 'INVALID_DAY');
    }
    if (input.frequency == ScheduledFrequency.weekly && input.weekday == null) {
      return const AppException('请选择每周执行日', code: 'INVALID_WEEKDAY');
    }
    if (input.endDate != null &&
        AppDateUtils.startOfDay(input.endDate!)
            .isBefore(AppDateUtils.startOfDay(input.startDate))) {
      return const AppException('结束日期不能早于开始日期', code: 'INVALID_RANGE');
    }
    return null;
  }

  String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
