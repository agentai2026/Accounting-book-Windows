import 'package:ezbookkeeping_desktop/core/database/daos/book_dao.dart';
import 'package:ezbookkeeping_desktop/core/models/book.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_exception.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';
import 'package:uuid/uuid.dart';

class BookService {
  BookService(this._bookDao);

  final BookDao _bookDao;
  static const _uuid = Uuid();

  Future<Result<Book>> createBook({
    required String name,
    String color = '#C07C4D',
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Result.failure(
        const AppException('账本名称不能为空', code: 'INVALID_NAME'),
      );
    }

    try {
      final now = DateTime.now();
      final sortOrder = await _bookDao.maxSortOrder() + 1;
      final book = Book(
        uuid: _uuid.v4(),
        name: trimmed,
        color: color,
        sortOrder: sortOrder,
        createdAt: now,
        updatedAt: now,
      );
      final id = await _bookDao.insert(book);
      return Result.success(book.copyWith(id: id));
    } catch (e, stack) {
      appLogger.e('创建账本失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('创建账本失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<Book>> updateBook(Book book, {required String name, String? color}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Result.failure(
        const AppException('账本名称不能为空', code: 'INVALID_NAME'),
      );
    }

    try {
      final updated = book.copyWith(
        name: trimmed,
        color: color ?? book.color,
        updatedAt: DateTime.now(),
      );
      await _bookDao.update(updated);
      return Result.success(updated);
    } catch (e, stack) {
      appLogger.e('更新账本失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('更新账本失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<void>> deleteBook(int id) async {
    try {
      final count = await _bookDao.countTransactions(id);
      if (count > 0) {
        return Result.failure(
          AppException('该账本已有 $count 笔交易，无法删除', code: 'IN_USE'),
        );
      }
      await _bookDao.softDelete(id, DateTime.now());
      return Result.success(null);
    } catch (e, stack) {
      appLogger.e('删除账本失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('删除账本失败', code: 'DB_ERROR'),
      );
    }
  }
}
