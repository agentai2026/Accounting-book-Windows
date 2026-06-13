import 'package:ezbookkeeping_desktop/core/database/daos/loan_dao.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/loan.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_exception.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';
import 'package:uuid/uuid.dart';

class LoanService {
  LoanService(this._loanDao);

  final LoanDao _loanDao;
  static const _uuid = Uuid();

  Future<Result<Loan>> createLoan({
    required LoanType type,
    required String person,
    required int amountCents,
    required DateTime date,
    DateTime? dueDate,
    String? description,
    int? bookId,
    int? accountId,
    bool excludeFromIo = true,
    bool excludeFromBudget = true,
  }) async {
    final trimmedPerson = person.trim();
    if (trimmedPerson.isEmpty) {
      return Result.failure(
        const AppException('请输入债务对象', code: 'INVALID_NAME'),
      );
    }
    if (amountCents <= 0) {
      return Result.failure(
        const AppException('金额必须大于 0', code: 'INVALID_AMOUNT'),
      );
    }

    try {
      final now = DateTime.now();
      final loan = Loan(
        uuid: _uuid.v4(),
        type: type,
        person: trimmedPerson,
        amount: amountCents,
        date: date,
        dueDate: dueDate,
        description: description?.trim(),
        bookId: bookId,
        accountId: accountId,
        excludeFromIo: excludeFromIo,
        excludeFromBudget: excludeFromBudget,
        createdAt: now,
        updatedAt: now,
      );
      final id = await _loanDao.insert(loan);
      return Result.success(loan.copyWith(id: id));
    } catch (e, stack) {
      appLogger.e('创建借贷记录失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('创建借贷记录失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<Loan>> updateLoan({
    required Loan loan,
    required LoanType type,
    required String person,
    required int amountCents,
    required DateTime date,
    DateTime? dueDate,
    String? description,
    int? bookId,
    int? accountId,
    bool? excludeFromIo,
    bool? excludeFromBudget,
    bool? isRepaid,
    bool clearDueDate = false,
  }) async {
    final trimmedPerson = person.trim();
    if (trimmedPerson.isEmpty) {
      return Result.failure(
        const AppException('请输入债务对象', code: 'INVALID_NAME'),
      );
    }

    try {
      final updated = loan.copyWith(
        type: type,
        person: trimmedPerson,
        amount: amountCents,
        date: date,
        dueDate: dueDate,
        clearDueDate: clearDueDate,
        description: description?.trim(),
        bookId: bookId,
        accountId: accountId,
        excludeFromIo: excludeFromIo,
        excludeFromBudget: excludeFromBudget,
        isRepaid: isRepaid ?? loan.isRepaid,
        updatedAt: DateTime.now(),
      );
      await _loanDao.update(updated);
      return Result.success(updated);
    } catch (e, stack) {
      appLogger.e('更新借贷记录失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('更新借贷记录失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<Loan>> toggleRepaid(Loan loan) async {
    return updateLoan(
      loan: loan,
      type: loan.type,
      person: loan.person,
      amountCents: loan.amount,
      date: loan.date,
      dueDate: loan.dueDate,
      description: loan.description,
      bookId: loan.bookId,
      accountId: loan.accountId,
      excludeFromIo: loan.excludeFromIo,
      excludeFromBudget: loan.excludeFromBudget,
      isRepaid: !loan.isRepaid,
    );
  }

  Future<Result<void>> deleteLoan(int id) async {
    try {
      await _loanDao.softDelete(id, DateTime.now());
      return Result.success(null);
    } catch (e, stack) {
      appLogger.e('删除借贷记录失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('删除借贷记录失败', code: 'DB_ERROR'),
      );
    }
  }
}
