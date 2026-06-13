import 'package:ezbookkeeping_desktop/core/database/daos/transaction_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/schema.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/services/statistics_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> _openTestDatabase() async {
  return openDatabase(
    inMemoryDatabasePath,
    version: 1,
    onConfigure: (database) async {
      await database.execute('PRAGMA foreign_keys = ON');
    },
    onCreate: (database, version) async {
      final statements = DatabaseSchema.v1Initial
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      for (final statement in statements) {
        await database.execute(statement);
      }
    },
  );
}

Future<int> _seedBook(Database db) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  final suffix = now.toString();
  return db.insert('books', {
    'uuid': 'book-test-$suffix',
    'name': '测试账本',
    'created_at': now,
    'updated_at': now,
  });
}

Future<int> _seedCategory(Database db) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  return db.insert('categories', {
    'uuid': 'cat-test-$now',
    'name': '测试分类',
    'type': CategoryType.expense.value,
    'created_at': now,
    'updated_at': now,
  });
}

Future<void> _seedTransaction(
  Database db, {
  required int bookId,
  required int categoryId,
  required TransactionType type,
  required int amount,
  required DateTime date,
}) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  await db.insert('transactions', {
    'uuid': 'tx-${type.value}-$amount-${date.millisecondsSinceEpoch}-$now',
    'book_id': bookId,
    'type': type.value,
    'amount': amount,
    'category_id': categoryId,
    'date': date.millisecondsSinceEpoch,
    'created_at': now,
    'updated_at': now,
  });
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('StatisticsService', () {
    late StatisticsService service;
    late int bookId;

    setUp(() async {
      final db = await _openTestDatabase();
      service = StatisticsService(TransactionDao(db));
      bookId = await _seedBook(db);
      final categoryId = await _seedCategory(db);
      await _seedTransaction(
        db,
        bookId: bookId,
        categoryId: categoryId,
        type: TransactionType.expense,
        amount: 5000,
        date: DateTime(2026, 6, 11, 10),
      );
      await _seedTransaction(
        db,
        bookId: bookId,
        categoryId: categoryId,
        type: TransactionType.income,
        amount: 12000,
        date: DateTime(2026, 6, 11, 14),
      );
      await _seedTransaction(
        db,
        bookId: bookId,
        categoryId: categoryId,
        type: TransactionType.expense,
        amount: 3000,
        date: DateTime(2026, 6, 10, 9),
      );
    });

    test('getPeriodSummary 汇总指定区间收支', () async {
      final summary = await service.getPeriodSummary(
        bookId,
        AppDateUtils.startOfDay(DateTime(2026, 6, 11)),
        AppDateUtils.endOfDay(DateTime(2026, 6, 11)),
      );

      expect(summary.expenseCents, 5000);
      expect(summary.incomeCents, 12000);
      expect(summary.netCents, 7000);
    });

    test('getDailyTrend 返回每日趋势点', () async {
      final trend = await service.getDailyTrend(
        bookId,
        AppDateUtils.startOfMonth(DateTime(2026, 6, 11)),
        AppDateUtils.endOfDay(DateTime(2026, 6, 11)),
      );

      expect(trend.length, 11);
      expect(trend.last.expenseCents, 5000);
      expect(trend[trend.length - 2].expenseCents, 3000);
    });

    test('getOverview 返回分类汇总', () async {
      final overview = await service.getOverview(
        bookId: bookId,
        start: AppDateUtils.startOfMonth(DateTime(2026, 6, 11)),
        end: AppDateUtils.endOfDay(DateTime(2026, 6, 11)),
        categoryNames: {1: '测试分类'},
      );

      expect(overview.summary.expenseCents, 8000);
      expect(overview.summary.incomeCents, 12000);
      expect(overview.expenseByCategory, hasLength(1));
      expect(overview.expenseByCategory.first.amountCents, 8000);
      expect(overview.incomeByCategory.first.amountCents, 12000);
    });
  });
}
