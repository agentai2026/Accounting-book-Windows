import 'package:ezbookkeeping_desktop/core/constants/transaction_flag_tags.dart';
import 'package:ezbookkeeping_desktop/core/models/transaction.dart' as models;
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/statistics_query.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:sqflite/sqflite.dart';

/// 收支统计口径筛选
enum TransactionIoFilter {
  any,
  excludeFromTotals,
  onlyInTotals,
}

/// 预算统计口径筛选
enum TransactionBudgetFilter {
  any,
  excludeFromBudget,
  onlyInBudget,
}

class TransactionQuery {
  const TransactionQuery({
    this.bookId,
    this.bookIds = const [],
    this.keyword,
    this.type,
    this.startDate,
    this.endDate,
    this.minAmountCents,
    this.maxAmountCents,
    this.accountIds = const [],
    this.categoryIds = const [],
    this.tagIds = const [],
    this.isReimbursable,
    this.hasImages,
    this.requireRefundTag = false,
    this.requireDiscountTag = false,
    this.requireReimbursedTag = false,
    this.excludeReimbursedTag = false,
    this.ioFilter = TransactionIoFilter.any,
    this.budgetFilter = TransactionBudgetFilter.any,
    this.budgetTrackedCategoryIds = const [],
    this.metadataCategoryKeywords = const [],
    this.unionCategoryAndMetadata = false,
    this.requireDuplicateCandidate = false,
    this.limit = 50,
    this.offset = 0,
  });

  final int? bookId;
  final List<int> bookIds;
  final String? keyword;
  final TransactionType? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? minAmountCents;
  final int? maxAmountCents;
  final List<int> accountIds;
  final List<int> categoryIds;
  final List<int> tagIds;
  final bool? isReimbursable;
  final bool? hasImages;
  final bool requireRefundTag;
  final bool requireDiscountTag;
  final bool requireReimbursedTag;
  final bool excludeReimbursedTag;
  final TransactionIoFilter ioFilter;
  final TransactionBudgetFilter budgetFilter;
  final List<int> budgetTrackedCategoryIds;
  final List<String> metadataCategoryKeywords;
  final bool unionCategoryAndMetadata;
  final bool requireDuplicateCandidate;
  final int limit;
  final int offset;
}

class TransactionDao {
  TransactionDao(this._db);

  final Database _db;
  static const _table = 'transactions';

  void _appendKeywordCondition(
    List<String> conditions,
    List<Object?> args,
    String? keyword,
  ) {
    if (keyword == null || keyword.trim().isEmpty) return;
    final parts = keyword
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    for (final part in parts) {
      conditions.add(
        '(comment LIKE ? OR description LIKE ? OR payer LIKE ?)',
      );
      final kw = '%$part%';
      args.addAll([kw, kw, kw]);
    }
  }

  void _appendAdvancedConditions(
    List<String> conditions,
    List<Object?> args,
    TransactionQuery query,
  ) {
    if (query.bookIds.isNotEmpty) {
      final placeholders = List.filled(query.bookIds.length, '?').join(', ');
      conditions.add('book_id IN ($placeholders)');
      args.addAll(query.bookIds);
    }
    if (query.minAmountCents != null) {
      conditions.add('amount >= ?');
      args.add(query.minAmountCents);
    }
    if (query.maxAmountCents != null) {
      conditions.add('amount <= ?');
      args.add(query.maxAmountCents);
    }
    if (query.accountIds.isNotEmpty) {
      final placeholders = List.filled(query.accountIds.length, '?').join(', ');
      conditions.add(
        '(from_account_id IN ($placeholders) OR to_account_id IN ($placeholders))',
      );
      args.addAll(query.accountIds);
      args.addAll(query.accountIds);
    }
    if (query.categoryIds.isNotEmpty) {
      if (query.unionCategoryAndMetadata) {
        _appendCategoryMetadataUnion(conditions, args, query);
      } else {
        final placeholders =
            List.filled(query.categoryIds.length, '?').join(', ');
        conditions.add('category_id IN ($placeholders)');
        args.addAll(query.categoryIds);
        _appendMetadataCategoryKeywords(
          conditions,
          query.metadataCategoryKeywords,
        );
      }
    } else {
      _appendMetadataCategoryKeywords(
        conditions,
        query.metadataCategoryKeywords,
      );
    }
    if (query.isReimbursable != null) {
      conditions.add('is_reimbursable = ?');
      args.add(query.isReimbursable! ? 1 : 0);
    }
    if (query.hasImages == true) {
      conditions.add(
        "images IS NOT NULL AND images != '' AND images != '[]'",
      );
    }
    for (final tagId in query.tagIds) {
      conditions.add(
        'id IN (SELECT transaction_id FROM transaction_tags WHERE tag_id = ?)',
      );
      args.add(tagId);
    }
    if (query.requireRefundTag) {
      conditions.add(
        '''id IN (
          SELECT tt.transaction_id FROM transaction_tags tt
          INNER JOIN tags t ON t.id = tt.tag_id
          WHERE t.name = ? AND t.deleted_at IS NULL
        )''',
      );
      args.add('退款');
    }
    if (query.requireDiscountTag) {
      conditions.add(
        '''id IN (
          SELECT tt.transaction_id FROM transaction_tags tt
          INNER JOIN tags t ON t.id = tt.tag_id
          WHERE t.name = ? AND t.deleted_at IS NULL
        )''',
      );
      args.add('优惠');
    }
    if (query.requireReimbursedTag) {
      conditions.add(
        '''id IN (
          SELECT tt.transaction_id FROM transaction_tags tt
          INNER JOIN tags t ON t.id = tt.tag_id
          WHERE t.name = ? AND t.deleted_at IS NULL
        )''',
      );
      args.add(TransactionFlagTags.reimbursed);
    }
    if (query.excludeReimbursedTag) {
      conditions.add(
        '''id NOT IN (
          SELECT tt.transaction_id FROM transaction_tags tt
          INNER JOIN tags t ON t.id = tt.tag_id
          WHERE t.name = ? AND t.deleted_at IS NULL
        )''',
      );
      args.add(TransactionFlagTags.reimbursed);
    }
    _appendIoFilter(conditions, args, query.ioFilter);
    _appendBudgetFilter(
      conditions,
      args,
      query.budgetFilter,
      query.budgetTrackedCategoryIds,
    );
    if (query.requireDuplicateCandidate) {
      conditions.add('''EXISTS (
        SELECT 1 FROM $_table dup
        WHERE dup.deleted_at IS NULL
          AND dup.id != $_table.id
          AND dup.amount = $_table.amount
          AND ABS(dup.date - $_table.date) <= ?
          AND (
            (dup.description IS NOT NULL AND dup.description != ''
              AND dup.description = $_table.description)
            OR (dup.comment IS NOT NULL AND dup.comment != ''
              AND dup.comment = $_table.comment)
          )
      )''');
      args.add(7 * 86400000);
    }
  }

  void _appendMetadataCategoryKeywords(
    List<String> conditions,
    List<String> keywords,
  ) {
    if (keywords.isEmpty) return;
    final parts = <String>[];
    for (final keyword in keywords) {
      parts.add("comment LIKE '%cat=$keyword%'");
    }
    conditions.add('(${parts.join(' OR ')})');
  }

  void _appendCategoryMetadataUnion(
    List<String> conditions,
    List<Object?> args,
    TransactionQuery query,
  ) {
    final parts = <String>[];
    if (query.categoryIds.isNotEmpty) {
      final placeholders =
          List.filled(query.categoryIds.length, '?').join(', ');
      parts.add('category_id IN ($placeholders)');
      args.addAll(query.categoryIds);
    }
    for (final keyword in query.metadataCategoryKeywords) {
      parts.add("comment LIKE '%cat=$keyword%'");
    }
    if (parts.isEmpty) return;
    conditions.add('(${parts.join(' OR ')})');
  }

  void _appendIoFilter(
    List<String> conditions,
    List<Object?> args,
    TransactionIoFilter filter,
  ) {
    const transferType = TransactionType.transfer;
    const excludeNeutral = '''(
      comment LIKE '%dir=不计收支%'
      OR comment LIKE '%dir=不计入收支%'
      OR comment LIKE '%dir=/%'
      OR comment LIKE '%dir=中性%'
      OR comment LIKE '%dir=中性交易%'
      OR comment LIKE '%cat=转账红包%'
      OR comment LIKE '%cat=账户存取%'
      OR comment LIKE '%cat=收钱码收款%'
    )''';

    switch (filter) {
      case TransactionIoFilter.any:
        break;
      case TransactionIoFilter.excludeFromTotals:
        conditions.add('''(
          type = ${transferType.value}
          OR (comment LIKE '%@src:%' AND $excludeNeutral)
          OR id IN (
            SELECT tt.transaction_id FROM transaction_tags tt
            INNER JOIN tags t ON t.id = tt.tag_id
            WHERE t.name = ? AND t.deleted_at IS NULL
          )
        )''');
        args.add(TransactionFlagTags.excludeFromIo);
      case TransactionIoFilter.onlyInTotals:
        conditions.add('''(
          type != ${transferType.value}
          AND (
            comment NOT LIKE '%@src:%'
            OR NOT $excludeNeutral
          )
          AND id NOT IN (
            SELECT tt.transaction_id FROM transaction_tags tt
            INNER JOIN tags t ON t.id = tt.tag_id
            WHERE t.name = ? AND t.deleted_at IS NULL
          )
        )''');
        args.add(TransactionFlagTags.excludeFromIo);
    }
  }

  void _appendBudgetFilter(
    List<String> conditions,
    List<Object?> args,
    TransactionBudgetFilter filter,
    List<int> budgetCategoryIds,
  ) {
    const expenseType = TransactionType.expense;
    switch (filter) {
      case TransactionBudgetFilter.any:
        break;
      case TransactionBudgetFilter.excludeFromBudget:
        if (budgetCategoryIds.isEmpty) {
          conditions.add('''(
            type != ${expenseType.value}
            OR id IN (
              SELECT tt.transaction_id FROM transaction_tags tt
              INNER JOIN tags t ON t.id = tt.tag_id
              WHERE t.name = ? AND t.deleted_at IS NULL
            )
          )''');
          args.add(TransactionFlagTags.excludeFromBudget);
        } else {
          final placeholders =
              List.filled(budgetCategoryIds.length, '?').join(', ');
          conditions.add('''(
            type != ${expenseType.value}
            OR category_id NOT IN ($placeholders)
            OR id IN (
              SELECT tt.transaction_id FROM transaction_tags tt
              INNER JOIN tags t ON t.id = tt.tag_id
              WHERE t.name = ? AND t.deleted_at IS NULL
            )
          )''');
          args.addAll(budgetCategoryIds);
          args.add(TransactionFlagTags.excludeFromBudget);
        }
      case TransactionBudgetFilter.onlyInBudget:
        if (budgetCategoryIds.isEmpty) {
          conditions.add('''(
            type = ${expenseType.value}
            AND id NOT IN (
              SELECT tt.transaction_id FROM transaction_tags tt
              INNER JOIN tags t ON t.id = tt.tag_id
              WHERE t.name = ? AND t.deleted_at IS NULL
            )
          )''');
          args.add(TransactionFlagTags.excludeFromBudget);
        } else {
          final placeholders =
              List.filled(budgetCategoryIds.length, '?').join(', ');
          conditions.add('''(
            type = ${expenseType.value}
            AND category_id IN ($placeholders)
            AND id NOT IN (
              SELECT tt.transaction_id FROM transaction_tags tt
              INNER JOIN tags t ON t.id = tt.tag_id
              WHERE t.name = ? AND t.deleted_at IS NULL
            )
          )''');
          args.addAll(budgetCategoryIds);
          args.add(TransactionFlagTags.excludeFromBudget);
        }
    }
  }

  Future<List<models.Transaction>> getAll({
    int? bookId,
    int limit = 50,
    int offset = 0,
  }) async {
    return search(TransactionQuery(
      bookId: bookId,
      limit: limit,
      offset: offset,
    ));
  }

  Future<List<models.Transaction>> search(TransactionQuery query) async {
    final conditions = <String>['deleted_at IS NULL'];
    final args = <Object?>[];

    if (query.bookId != null) {
      conditions.add('book_id = ?');
      args.add(query.bookId);
    }
    if (query.type != null) {
      conditions.add('type = ?');
      args.add(query.type!.value);
    }
    if (query.startDate != null) {
      conditions.add('date >= ?');
      args.add(query.startDate!.millisecondsSinceEpoch);
    }
    if (query.endDate != null) {
      conditions.add('date <= ?');
      args.add(query.endDate!.millisecondsSinceEpoch);
    }
    _appendKeywordCondition(conditions, args, query.keyword);
    _appendAdvancedConditions(conditions, args, query);

    final rows = await _db.query(
      _table,
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'date DESC, id DESC',
      limit: query.limit,
      offset: query.offset,
    );
    return rows.map(models.Transaction.fromMap).toList();
  }

  Future<int> countQuery(TransactionQuery query) async {
    final conditions = <String>['deleted_at IS NULL'];
    final args = <Object?>[];

    if (query.bookId != null) {
      conditions.add('book_id = ?');
      args.add(query.bookId);
    }
    if (query.type != null) {
      conditions.add('type = ?');
      args.add(query.type!.value);
    }
    if (query.startDate != null) {
      conditions.add('date >= ?');
      args.add(query.startDate!.millisecondsSinceEpoch);
    }
    if (query.endDate != null) {
      conditions.add('date <= ?');
      args.add(query.endDate!.millisecondsSinceEpoch);
    }
    _appendKeywordCondition(conditions, args, query.keyword);
    _appendAdvancedConditions(conditions, args, query);

    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM $_table WHERE ${conditions.join(' AND ')}',
      args,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> count({
    int? bookId,
    TransactionType? type,
    String? keyword,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return countQuery(
      TransactionQuery(
        bookId: bookId,
        type: type,
        keyword: keyword,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  Future<({int expenseCents, int incomeCents})> sumIncomeExpenseQuery(
    TransactionQuery query,
  ) async {
    Future<int> sumFor(TransactionType transactionType) async {
      if (query.type != null && query.type != transactionType) return 0;

      final conditions = <String>[
        'deleted_at IS NULL',
        'type = ?',
      ];
      final args = <Object?>[transactionType.value];

      if (query.bookId != null) {
        conditions.add('book_id = ?');
        args.add(query.bookId);
      }
      if (query.startDate != null) {
        conditions.add('date >= ?');
        args.add(query.startDate!.millisecondsSinceEpoch);
      }
      if (query.endDate != null) {
        conditions.add('date <= ?');
        args.add(query.endDate!.millisecondsSinceEpoch);
      }
      _appendKeywordCondition(conditions, args, query.keyword);
      _appendAdvancedConditions(conditions, args, query);

      final result = await _db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM $_table WHERE ${conditions.join(' AND ')}',
        args,
      );
      return Sqflite.firstIntValue(result) ?? 0;
    }

    final expense = await sumFor(TransactionType.expense);
    final income = await sumFor(TransactionType.income);
    return (expenseCents: expense, incomeCents: income);
  }

  Future<({int expenseCents, int incomeCents})> sumIncomeExpense({
    int? bookId,
    TransactionType? type,
    String? keyword,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Future<int> sumFor(TransactionType transactionType) async {
      if (type != null && type != transactionType) return 0;

      final conditions = <String>[
        'deleted_at IS NULL',
        'type = ?',
      ];
      final args = <Object?>[transactionType.value];

      if (bookId != null) {
        conditions.add('book_id = ?');
        args.add(bookId);
      }
      if (startDate != null) {
        conditions.add('date >= ?');
        args.add(startDate.millisecondsSinceEpoch);
      }
      if (endDate != null) {
        conditions.add('date <= ?');
        args.add(endDate.millisecondsSinceEpoch);
      }
      _appendKeywordCondition(conditions, args, keyword);

      final result = await _db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM $_table WHERE ${conditions.join(' AND ')}',
        args,
      );
      return Sqflite.firstIntValue(result) ?? 0;
    }

    final expense = await sumFor(TransactionType.expense);
    final income = await sumFor(TransactionType.income);
    return (expenseCents: expense, incomeCents: income);
  }

  Future<List<models.Transaction>> listAllActive({int? bookId}) async {
    final conditions = <String>['deleted_at IS NULL'];
    final args = <Object?>[];

    if (bookId != null) {
      conditions.add('book_id = ?');
      args.add(bookId);
    }

    final rows = await _db.query(
      _table,
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'date ASC, id ASC',
    );
    return rows.map(models.Transaction.fromMap).toList();
  }

  Future<int> sumAmountByType({
    required int bookId,
    required TransactionType type,
    required DateTime start,
    required DateTime end,
  }) async {
    final result = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total FROM $_table
      WHERE book_id = ? AND type = ? AND deleted_at IS NULL
      AND date >= ? AND date <= ?
      ''',
      [
        bookId,
        type.value,
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> sumAmountGroupByDay({
    required int bookId,
    required TransactionType type,
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await _db.rawQuery(
      '''
      SELECT strftime('%Y-%m-%d', date / 1000, 'unixepoch', 'localtime') as day_key,
             COALESCE(SUM(amount), 0) as total
      FROM $_table
      WHERE book_id = ? AND type = ? AND deleted_at IS NULL
        AND date >= ? AND date <= ?
      GROUP BY day_key
      ORDER BY day_key ASC
      ''',
      [
        bookId,
        type.value,
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
    );

    return {
      for (final row in rows)
        row['day_key'] as String: row['total'] as int? ?? 0,
    };
  }

  Future<Map<String, int>> sumAmountGroupByMonth({
    int? bookId,
    required TransactionType type,
    required DateTime start,
    required DateTime end,
  }) async {
    final conditions = <String>[
      'type = ?',
      'deleted_at IS NULL',
      'date >= ?',
      'date <= ?',
    ];
    final args = <Object?>[
      type.value,
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
    ];
    if (bookId != null) {
      conditions.insert(0, 'book_id = ?');
      args.insert(0, bookId);
    }

    final rows = await _db.rawQuery(
      '''
      SELECT strftime('%Y-%m', date / 1000, 'unixepoch', 'localtime') as month_key,
             COALESCE(SUM(amount), 0) as total
      FROM $_table
      WHERE ${conditions.join(' AND ')}
      GROUP BY month_key
      ORDER BY month_key ASC
      ''',
      args,
    );

    return {
      for (final row in rows)
        row['month_key'] as String: row['total'] as int? ?? 0,
    };
  }

  Future<Map<int, int>> sumAmountGroupByCategory({
    required int bookId,
    required TransactionType type,
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await _db.rawQuery(
      '''
      SELECT category_id, COALESCE(SUM(amount), 0) as total
      FROM $_table
      WHERE book_id = ? AND type = ? AND deleted_at IS NULL
        AND date >= ? AND date <= ?
      GROUP BY category_id
      ORDER BY total DESC
      ''',
      [
        bookId,
        type.value,
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
    );

    return {
      for (final row in rows)
        row['category_id'] as int: row['total'] as int? ?? 0,
    };
  }

  Future<Map<String, int>> sumAmountGroupByMonthForCategory({
    int? bookId,
    required int categoryId,
    required DateTime start,
    required DateTime end,
    String? keyword,
  }) async {
    final conditions = <String>[
      'category_id = ?',
      'type = ?',
      'deleted_at IS NULL',
      'date >= ?',
      'date <= ?',
    ];
    final args = <Object?>[
      categoryId,
      TransactionType.expense.value,
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
    ];
    if (bookId != null) {
      conditions.insert(0, 'book_id = ?');
      args.insert(0, bookId);
    }

    _appendKeywordCondition(conditions, args, keyword);

    final rows = await _db.rawQuery(
      '''
      SELECT strftime('%Y-%m', date / 1000, 'unixepoch', 'localtime') as month_key,
             COALESCE(SUM(amount), 0) as total
      FROM $_table
      WHERE ${conditions.join(' AND ')}
      GROUP BY month_key
      ORDER BY month_key ASC
      ''',
      args,
    );

    return {
      for (final row in rows)
        row['month_key'] as String: row['total'] as int? ?? 0,
    };
  }

  Future<models.Transaction?> getById(int id) async {
    final rows = await _db.query(
      _table,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return models.Transaction.fromMap(rows.first);
  }

  Future<models.Transaction?> getByUuid(String uuid) async {
    final rows = await _db.query(
      _table,
      where: 'uuid = ? AND deleted_at IS NULL',
      whereArgs: [uuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return models.Transaction.fromMap(rows.first);
  }

  Future<bool> existsForScheduledOnDay(int scheduledId, DateTime day) async {
    final start = AppDateUtils.startOfDay(day).millisecondsSinceEpoch;
    final end = AppDateUtils.endOfDay(day).millisecondsSinceEpoch;
    final rows = await _db.query(
      _table,
      columns: ['id'],
      where:
          'deleted_at IS NULL AND scheduled_transaction_id = ? AND date >= ? AND date <= ?',
      whereArgs: [scheduledId, start, end],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// 周期记账已生成的账单（按日期倒序）
  Future<List<models.Transaction>> getByScheduledTransactionId(
    int scheduledId, {
    int limit = 8,
  }) async {
    final rows = await _db.query(
      _table,
      where: 'deleted_at IS NULL AND scheduled_transaction_id = ?',
      whereArgs: [scheduledId],
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map(models.Transaction.fromMap).toList();
  }

  Future<int> countByScheduledTransactionId(int scheduledId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT COUNT(*) AS c FROM $_table
      WHERE deleted_at IS NULL AND scheduled_transaction_id = ?
      ''',
      [scheduledId],
    );
    return rows.first['c'] as int? ?? 0;
  }

  /// 关联账单：同周期规则、同金额近邻、退款标签同类
  Future<List<models.Transaction>> findRelatedTransactions(
    models.Transaction transaction,
  ) async {
    final id = transaction.id;
    if (id == null) return const [];

    final seen = <int>{id};
    final results = <models.Transaction>[];

    void addRows(List<Map<String, Object?>> rows) {
      for (final row in rows) {
        final tx = models.Transaction.fromMap(row);
        if (tx.id != null && seen.add(tx.id!)) {
          results.add(tx);
        }
      }
    }

    if (transaction.scheduledTransactionId != null) {
      addRows(
        await _db.query(
          _table,
          where:
              'deleted_at IS NULL AND scheduled_transaction_id = ? AND id != ?',
          whereArgs: [transaction.scheduledTransactionId, id],
          orderBy: 'date DESC',
          limit: 10,
        ),
      );
    }

    addRows(
      await _db.query(
        _table,
        where: '''deleted_at IS NULL
          AND book_id = ?
          AND id != ?
          AND amount = ?
          AND ABS(date - ?) <= ?''',
        whereArgs: [
          transaction.bookId,
          id,
          transaction.amount,
          transaction.date.millisecondsSinceEpoch,
          7 * 86400000,
        ],
        orderBy: 'date DESC',
        limit: 8,
      ),
    );

    addRows(
      await _db.rawQuery(
        '''
        SELECT tr.*
        FROM $_table tr
        INNER JOIN transaction_tags tt ON tt.transaction_id = tr.id
        INNER JOIN tags t ON t.id = tt.tag_id
        WHERE tr.deleted_at IS NULL
          AND tr.book_id = ?
          AND tr.id != ?
          AND tr.amount = ?
          AND t.name = ?
          AND t.deleted_at IS NULL
        ORDER BY tr.date DESC
        LIMIT 5
        ''',
        [
          transaction.bookId,
          id,
          transaction.amount,
          TransactionFlagTags.refund,
        ],
      ),
    );

    return results;
  }

  Future<int> insert(models.Transaction transaction) async {
    return _db.insert(_table, transaction.toMap());
  }

  Future<int> update(models.Transaction transaction) async {
    return _db.update(
      _table,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> softDelete(int id, DateTime deletedAt) async {
    return _db.update(
      _table,
      {
        'deleted_at': deletedAt.millisecondsSinceEpoch,
        'updated_at': deletedAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  ({List<String> conditions, List<Object?> args}) _statisticsConditions(
    StatisticsQueryParams query, {
    TransactionType? forceType,
  }) {
    final conditions = <String>['deleted_at IS NULL'];
    final args = <Object?>[];

    if (query.bookId != null) {
      conditions.add('book_id = ?');
      args.add(query.bookId);
    }

    final type = forceType ?? query.type;
    if (type != null) {
      conditions.add('type = ?');
      args.add(type.value);
    }

    conditions.add('date >= ?');
    args.add(query.start.millisecondsSinceEpoch);
    conditions.add('date <= ?');
    args.add(query.end.millisecondsSinceEpoch);

    _appendKeywordCondition(conditions, args, query.keyword);

    if (query.accountId != null) {
      conditions.add(
        '(from_account_id = ? OR to_account_id = ?)',
      );
      args.addAll([query.accountId, query.accountId]);
    }

    return (conditions: conditions, args: args);
  }

  Future<({DateTime? min, DateTime? max})> getStatisticsDateBounds(
    StatisticsQueryParams query,
  ) async {
    final built = _statisticsConditions(query);
    final result = await _db.rawQuery(
      '''
      SELECT MIN(date) as min_date, MAX(date) as max_date
      FROM $_table
      WHERE ${built.conditions.join(' AND ')}
      ''',
      built.args,
    );
    if (result.isEmpty) return (min: null, max: null);
    final minMs = result.first['min_date'] as int?;
    final maxMs = result.first['max_date'] as int?;
    return (
      min: minMs != null
          ? DateTime.fromMillisecondsSinceEpoch(minMs)
          : null,
      max: maxMs != null
          ? DateTime.fromMillisecondsSinceEpoch(maxMs)
          : null,
    );
  }

  Future<int> countStatistics(StatisticsQueryParams query) async {
    final built = _statisticsConditions(query);
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM $_table WHERE ${built.conditions.join(' AND ')}',
      built.args,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> sumAmountStatistics(
    StatisticsQueryParams query, {
    required TransactionType type,
  }) async {
    final built = _statisticsConditions(query, forceType: type);
    final result = await _db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM $_table WHERE ${built.conditions.join(' AND ')}',
      built.args,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<({int count, int amountCents})> sumReimbursableStatistics(
    StatisticsQueryParams query,
  ) async {
    return sumReimbursementStatistics(
      bookId: query.bookId,
      status: ReimbursementStatus.pending,
      startDate: query.start,
      endDate: query.end,
    );
  }

  Future<({int count, int amountCents})> sumReimbursementStatistics({
    int? bookId,
    required ReimbursementStatus status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final conditions = <String>[
      'deleted_at IS NULL',
      'type = ?',
      'is_reimbursable = 1',
    ];
    final args = <Object?>[TransactionType.expense.value];

    if (bookId != null) {
      conditions.add('book_id = ?');
      args.add(bookId);
    }
    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate.millisecondsSinceEpoch);
    }

    switch (status) {
      case ReimbursementStatus.pending:
        conditions.add(
          '''id NOT IN (
            SELECT tt.transaction_id FROM transaction_tags tt
            INNER JOIN tags t ON t.id = tt.tag_id
            WHERE t.name = ? AND t.deleted_at IS NULL
          )''',
        );
        args.add(TransactionFlagTags.reimbursed);
      case ReimbursementStatus.reimbursed:
        conditions.add(
          '''id IN (
            SELECT tt.transaction_id FROM transaction_tags tt
            INNER JOIN tags t ON t.id = tt.tag_id
            WHERE t.name = ? AND t.deleted_at IS NULL
          )''',
        );
        args.add(TransactionFlagTags.reimbursed);
      case ReimbursementStatus.all:
        break;
    }

    final where = conditions.join(' AND ');
    final countResult = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM $_table WHERE $where',
      args,
    );
    final sumResult = await _db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM $_table WHERE $where',
      args,
    );
    return (
      count: Sqflite.firstIntValue(countResult) ?? 0,
      amountCents: Sqflite.firstIntValue(sumResult) ?? 0,
    );
  }

  Future<List<({int type, int amount, String? comment})>> listStatisticsBrief(
    StatisticsQueryParams query,
  ) async {
    final built = _statisticsConditions(query);
    final rows = await _db.rawQuery(
      'SELECT type, amount, comment FROM $_table WHERE ${built.conditions.join(' AND ')}',
      built.args,
    );
    return rows
        .map(
          (row) => (
            type: row['type'] as int,
            amount: row['amount'] as int? ?? 0,
            comment: row['comment'] as String?,
          ),
        )
        .toList();
  }

  Future<Map<int, int>> sumAmountGroupByCategoryFiltered(
    StatisticsQueryParams query, {
    required TransactionType type,
  }) async {
    final built = _statisticsConditions(query, forceType: type);
    final rows = await _db.rawQuery(
      '''
      SELECT category_id, COALESCE(SUM(amount), 0) as total
      FROM $_table
      WHERE ${built.conditions.join(' AND ')}
      GROUP BY category_id
      ORDER BY total DESC
      ''',
      built.args,
    );
    return {
      for (final row in rows)
        row['category_id'] as int: row['total'] as int? ?? 0,
    };
  }

  Future<Map<int, int>> sumAmountGroupByAccountFiltered(
    StatisticsQueryParams query, {
    required TransactionType type,
  }) async {
    final built = _statisticsConditions(query, forceType: type);
    final column = type == TransactionType.income ? 'to_account_id' : 'from_account_id';
    final rows = await _db.rawQuery(
      '''
      SELECT $column as account_id, COALESCE(SUM(amount), 0) as total
      FROM $_table
      WHERE ${built.conditions.join(' AND ')} AND $column IS NOT NULL
      GROUP BY $column
      ORDER BY total DESC
      ''',
      built.args,
    );
    return {
      for (final row in rows)
        if (row['account_id'] != null)
          row['account_id'] as int: row['total'] as int? ?? 0,
    };
  }

  Future<Map<String, int>> sumAmountGroupByDayFiltered(
    StatisticsQueryParams query, {
    required TransactionType type,
  }) async {
    final built = _statisticsConditions(query, forceType: type);
    final rows = await _db.rawQuery(
      '''
      SELECT strftime('%Y-%m-%d', date / 1000, 'unixepoch', 'localtime') as day_key,
             COALESCE(SUM(amount), 0) as total
      FROM $_table
      WHERE ${built.conditions.join(' AND ')}
      GROUP BY day_key
      ORDER BY day_key ASC
      ''',
      built.args,
    );
    return {
      for (final row in rows)
        row['day_key'] as String: row['total'] as int? ?? 0,
    };
  }

  Future<Map<String, int>> sumAmountGroupByMonthFiltered(
    StatisticsQueryParams query, {
    required TransactionType type,
  }) async {
    final built = _statisticsConditions(query, forceType: type);
    final rows = await _db.rawQuery(
      '''
      SELECT strftime('%Y-%m', date / 1000, 'unixepoch', 'localtime') as month_key,
             COALESCE(SUM(amount), 0) as total
      FROM $_table
      WHERE ${built.conditions.join(' AND ')}
      GROUP BY month_key
      ORDER BY month_key ASC
      ''',
      built.args,
    );
    return {
      for (final row in rows)
        row['month_key'] as String: row['total'] as int? ?? 0,
    };
  }
}
