import 'dart:math';

import 'package:ezbookkeeping_desktop/core/constants/default_account_presets.dart';
import 'package:ezbookkeeping_desktop/core/constants/default_category_presets.dart';
import 'package:ezbookkeeping_desktop/core/constants/demo_transaction_data.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/account_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/book_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/category_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/tag_dao.dart';
import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/tag.dart';
import 'package:ezbookkeeping_desktop/core/services/account_service.dart';
import 'package:ezbookkeeping_desktop/core/services/bookkeeping_service.dart';
import 'package:ezbookkeeping_desktop/core/services/category_service.dart';
import 'package:ezbookkeeping_desktop/core/services/create_transaction_input.dart';
import 'package:ezbookkeeping_desktop/core/services/tag_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_exception.dart';
import 'package:ezbookkeeping_desktop/core/utils/label_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DemoTransactionSeedService {
  DemoTransactionSeedService({
    required Database database,
    required BookkeepingService bookkeepingService,
    required AccountService accountService,
    required CategoryService categoryService,
    required TagService tagService,
    required BookDao bookDao,
    required AccountDao accountDao,
    required CategoryDao categoryDao,
    required TagDao tagDao,
  })  : _db = database,
        _bookkeepingService = bookkeepingService,
        _accountService = accountService,
        _categoryService = categoryService,
        _tagService = tagService,
        _bookDao = bookDao,
        _accountDao = accountDao,
        _categoryDao = categoryDao,
        _tagDao = tagDao;

  final Database _db;
  final BookkeepingService _bookkeepingService;
  final AccountService _accountService;
  final CategoryService _categoryService;
  final TagService _tagService;
  final BookDao _bookDao;
  final AccountDao _accountDao;
  final CategoryDao _categoryDao;
  final TagDao _tagDao;
  static const _uuid = Uuid();

  /// 生成约 [targetCount] 条演示交易（默认 100），自动补齐账户/分类/标签。
  Future<Result<int>> seed({int targetCount = 100}) async {
    if (targetCount <= 0) {
      return Result.failure(
        const AppException('生成数量必须大于 0', code: 'INVALID_COUNT'),
      );
    }

    try {
      await _ensureTransactionColumns();
      final bookId = await _resolveBookId();
      if (bookId == null) {
        return Result.failure(
          const AppException('未找到可用账本', code: 'NO_BOOK'),
        );
      }

      await _ensureAccounts(bookId);
      await _ensureCategories();
      final tagIds = await _ensureTags();

      final accounts = await _accountDao.getAll(bookId: bookId);
      final categories = await _categoryDao.getAll();
      if (accounts.isEmpty) {
        return Result.failure(
          const AppException('请先添加至少一个账户', code: 'NO_ACCOUNT'),
        );
      }

      final expenseCount = (targetCount * 0.72).round();
      final incomeCount = (targetCount * 0.2).round();
      final transferCount = targetCount - expenseCount - incomeCount;

      final random = Random(20260611);
      var created = 0;
      final timezoneOffset = DateTime.now().timeZoneOffset.inMinutes;

      created += await _createBatch(
        random: random,
        bookId: bookId,
        type: TransactionType.expense,
        count: expenseCount,
        accounts: accounts,
        categories: categories,
        tagIds: tagIds,
        timezoneOffset: timezoneOffset,
      );
      created += await _createBatch(
        random: random,
        bookId: bookId,
        type: TransactionType.income,
        count: incomeCount,
        accounts: accounts,
        categories: categories,
        tagIds: tagIds,
        timezoneOffset: timezoneOffset,
      );
      created += await _createBatch(
        random: random,
        bookId: bookId,
        type: TransactionType.transfer,
        count: transferCount,
        accounts: accounts,
        categories: categories,
        tagIds: tagIds,
        timezoneOffset: timezoneOffset,
      );

      if (created == 0) {
        return Result.failure(
          const AppException(
            '未能创建交易，请确认已添加账户与二级分类',
            code: 'SEED_EMPTY',
          ),
        );
      }

      return Result.success(created);
    } catch (e) {
      return Result.failure(
        AppException('生成演示数据失败: $e', code: 'SEED_ERROR'),
      );
    }
  }

  Future<void> _ensureTransactionColumns() async {
    final info = await _db.rawQuery('PRAGMA table_info(transactions)');
    final columns = info.map((row) => row['name'] as String).toSet();
    if (!columns.contains('comment')) {
      await _db.execute('ALTER TABLE transactions ADD COLUMN comment TEXT');
    }
    if (!columns.contains('payer')) {
      await _db.execute('ALTER TABLE transactions ADD COLUMN payer TEXT');
    }
  }

  Future<int?> _resolveBookId() async {
    final books = await _bookDao.getAll();
    if (books.isEmpty) return null;
    return books.first.id;
  }

  Future<void> _ensureAccounts(int bookId) async {
    final accounts = await _accountDao.getAll(bookId: bookId);
    if (accounts.isNotEmpty) return;

    await _accountService.createPresetAccounts(
      bookId: bookId,
      presets: kDefaultAccountPresets,
    );
  }

  Future<void> _ensureCategories() async {
    for (final type in CategoryType.values) {
      await _ensureCategoryChildren(type);
    }
  }

  Future<void> _ensureCategoryChildren(CategoryType type) async {
    final categories = await _categoryDao.getAll();
    if (categories.any((c) => c.type == type && c.parentId != null)) {
      return;
    }

    final presets = defaultCategoryPresetsFor(type);
    final now = DateTime.now();

    for (var rootIndex = 0; rootIndex < presets.length; rootIndex++) {
      final group = presets[rootIndex];
      final existingRoot = categories.where(
        (c) => c.type == type && c.parentId == null && c.name == group.name,
      );
      int rootId;
      if (existingRoot.isNotEmpty && existingRoot.first.id != null) {
        rootId = existingRoot.first.id!;
      } else {
        rootId = await _categoryDao.insert(
          Category(
            uuid: _uuid.v4(),
            name: group.name,
            type: type,
            icon: group.icon,
            sortOrder: rootIndex,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      final existingChildNames = categories
          .where((c) => c.parentId == rootId)
          .map((c) => c.name)
          .toSet();

      for (var childIndex = 0; childIndex < group.children.length; childIndex++) {
        final child = group.children[childIndex];
        if (existingChildNames.contains(child.name)) continue;
        await _categoryDao.insert(
          Category(
            uuid: _uuid.v4(),
            parentId: rootId,
            name: child.name,
            type: type,
            icon: child.icon,
            sortOrder: childIndex,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }
  }

  Future<Map<String, int>> _ensureTags() async {
    final existing = await _tagDao.getAll();
    final byName = {
      for (final tag in existing)
        if (tag.id != null) tag.name: tag.id!,
    };

    for (final name in DemoTransactionData.demoTags) {
      if (byName.containsKey(name)) continue;
      final result = await _tagService.createTag(name);
      result.when(
        success: (tag) {
          if (tag.id != null) byName[name] = tag.id!;
        },
        failure: (_) {},
      );
    }

    return byName;
  }

  Future<int> _createBatch({
    required Random random,
    required int bookId,
    required TransactionType type,
    required int count,
    required List<Account> accounts,
    required List<Category> categories,
    required Map<String, int> tagIds,
    required int timezoneOffset,
  }) async {
    var created = 0;
    String? firstError;
    var skipped = 0;
    for (var i = 0; i < count; i++) {
      final input = _buildInput(
        random: random,
        bookId: bookId,
        type: type,
        accounts: accounts,
        categories: categories,
        tagIds: tagIds,
        timezoneOffset: timezoneOffset,
        index: i,
      );
      if (input == null) {
        skipped++;
        continue;
      }

      final result = await _bookkeepingService.createTransaction(input);
      result.when(
        success: (_) => created++,
        failure: (error) => firstError ??= error.message,
      );
    }
    if (created == 0 && firstError != null) {
      throw AppException(firstError!, code: 'CREATE_FAILED');
    }
    if (created == 0 && skipped == count) {
      throw AppException(
        '没有可用的${transactionTypeLabel(type)}二级分类',
        code: 'NO_CATEGORY',
      );
    }
    return created;
  }

  CreateTransactionInput? _buildInput({
    required Random random,
    required int bookId,
    required TransactionType type,
    required List<Account> accounts,
    required List<Category> categories,
    required Map<String, int> tagIds,
    required int timezoneOffset,
    required int index,
  }) {
    final category = _pickCategory(random, categories, type);
    if (category?.id == null) return null;

    final date = _randomDate(random, index);
    final account = accounts[random.nextInt(accounts.length)];
    final accountId = account.id;
    if (accountId == null) return null;

    return switch (type) {
      TransactionType.expense => CreateTransactionInput(
          bookId: bookId,
          type: type,
          amountInCents: _expenseAmount(random),
          categoryId: category!.id!,
          fromAccountId: accountId,
          date: date,
          timezoneUtcOffset: timezoneOffset,
          comment: _pick(
            random,
            DemoTransactionData.expenseComments,
          ),
          payer: _pick(random, DemoTransactionData.expensePayers),
          tagIds: _pickTagIds(random, tagIds, type),
          isReimbursable: random.nextInt(100) < 18,
        ),
      TransactionType.income => CreateTransactionInput(
          bookId: bookId,
          type: type,
          amountInCents: _incomeAmount(random),
          categoryId: category!.id!,
          toAccountId: accountId,
          date: date,
          timezoneUtcOffset: timezoneOffset,
          comment: _pick(random, DemoTransactionData.incomeComments),
          payer: _pick(random, DemoTransactionData.incomePayers),
          tagIds: _pickTagIds(random, tagIds, type),
        ),
      TransactionType.transfer => _buildTransferInput(
          random: random,
          bookId: bookId,
          categoryId: category!.id!,
          accounts: accounts,
          date: date,
          timezoneOffset: timezoneOffset,
          tagIds: tagIds,
        ),
    };
  }

  CreateTransactionInput? _buildTransferInput({
    required Random random,
    required int bookId,
    required int categoryId,
    required List<Account> accounts,
    required DateTime date,
    required int timezoneOffset,
    required Map<String, int> tagIds,
  }) {
    if (accounts.length < 2) return null;

    final from = accounts[random.nextInt(accounts.length)];
    var to = accounts[random.nextInt(accounts.length)];
    if (to.id == from.id) {
      to = accounts.firstWhere(
        (a) => a.id != from.id,
        orElse: () => accounts.first,
      );
    }
    if (from.id == null || to.id == null) return null;

    return CreateTransactionInput(
      bookId: bookId,
      type: TransactionType.transfer,
      amountInCents: _transferAmount(random),
      categoryId: categoryId,
      fromAccountId: from.id,
      toAccountId: to.id,
      date: date,
      timezoneUtcOffset: timezoneOffset,
      comment: _pick(random, DemoTransactionData.transferComments),
      payer: '本人',
      tagIds: _pickTagIds(random, tagIds, TransactionType.transfer),
    );
  }

  Category? _pickCategory(
    Random random,
    List<Category> categories,
    TransactionType type,
  ) {
    final categoryType = CategoryType.fromValue(type.value);
    final childNames = switch (type) {
      TransactionType.expense => DemoTransactionData.expenseChildCategories,
      TransactionType.income => DemoTransactionData.incomeChildCategories,
      TransactionType.transfer => DemoTransactionData.transferChildCategories,
    };

    final preferredName = childNames[random.nextInt(childNames.length)];
    final preferred = categories.where(
      (c) =>
          c.type == categoryType &&
          c.parentId != null &&
          c.name == preferredName &&
          c.id != null,
    );
    if (preferred.isNotEmpty) return preferred.first;

    final fallback = categories
        .where(
          (c) => c.type == categoryType && c.parentId != null && c.id != null,
        )
        .toList();
    if (fallback.isEmpty) return null;
    return fallback[random.nextInt(fallback.length)];
  }

  List<int> _pickTagIds(
    Random random,
    Map<String, int> tagIds,
    TransactionType type,
  ) {
    if (tagIds.isEmpty || random.nextInt(100) > 62) return const [];

    final names = tagIds.keys.toList();
    final count = 1 + random.nextInt(2);
    final picked = <int>{};

    final preferredTags = switch (type) {
      TransactionType.expense => ['餐饮', '生活', '工作', '报销', '网购'],
      TransactionType.income => ['工作', '家庭', '日常'],
      TransactionType.transfer => ['日常', '工作', '家庭'],
    };

    for (final name in preferredTags) {
      final id = tagIds[name];
      if (id != null && random.nextBool()) picked.add(id);
    }

    while (picked.length < count && picked.length < names.length) {
      final id = tagIds[names[random.nextInt(names.length)]];
      if (id != null) picked.add(id);
    }

    return picked.toList();
  }

  DateTime _randomDate(Random random, int index) {
    final daysAgo = random.nextInt(150) + index % 3;
    final hour = 8 + random.nextInt(13);
    final minute = random.nextInt(60);
    final second = random.nextInt(60);
    final base = DateTime.now().subtract(Duration(days: daysAgo));
    return DateTime(base.year, base.month, base.day, hour, minute, second);
  }

  int _expenseAmount(Random random) {
    final buckets = [350, 680, 1200, 2800, 4500, 8900, 12800, 25600, 39900];
    return buckets[random.nextInt(buckets.length)] +
        random.nextInt(99);
  }

  int _incomeAmount(Random random) {
    final buckets = [
      88000,
      120000,
      150000,
      280000,
      350000,
      520000,
      80000,
      20000,
      66000,
    ];
    return buckets[random.nextInt(buckets.length)];
  }

  int _transferAmount(Random random) {
    final buckets = [50000, 100000, 200000, 300000, 80000, 150000];
    return buckets[random.nextInt(buckets.length)];
  }

  String _pick(Random random, List<String> items) {
    return items[random.nextInt(items.length)];
  }
}
