import 'package:ezbookkeeping_desktop/core/constants/default_category_presets.dart';
import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// 默认分类树（与 ezBookkeeping 参考版一致）
class DefaultCategoryData {
  DefaultCategoryData._();

  static const _uuid = Uuid();

  static Future<void> seedAll(Database db) async {
    await _seedType(db, CategoryType.expense, kDefaultExpenseCategoryPresets);
    await _seedType(db, CategoryType.income, kDefaultIncomeCategoryPresets);
    await _seedType(db, CategoryType.transfer, kDefaultTransferCategoryPresets);
  }

  /// 从旧版扁平分类迁移到完整分类树
  static Future<void> migrateFromLegacyFlat(Database db) async {
    final rows = await db.query(
      'categories',
      where: 'deleted_at IS NULL',
    );
    if (rows.isEmpty) return;
    final hasHierarchy = rows.any((row) => row['parent_id'] != null);
    if (hasHierarchy) return;

    await seedAll(db);

    final newCategories = await db.query(
      'categories',
      where: 'deleted_at IS NULL',
    );
    final newByPath = <String, int>{};
    for (final row in newCategories) {
      final id = row['id'] as int?;
      final name = row['name'] as String?;
      final parentId = row['parent_id'] as int?;
      if (id == null || name == null) continue;
      if (parentId == null) {
        newByPath[name] = id;
      } else {
        final parent = newCategories.firstWhere(
          (item) => item['id'] == parentId,
          orElse: () => const {},
        );
        final parentName = parent['name'] as String?;
        if (parentName != null) {
          newByPath['$parentName>$name'] = id;
        }
      }
    }

    int? resolveNewId(String path) => newByPath[path];

    final legacyExpenseMap = {
      '餐饮': resolveNewId('食品饮料>食品'),
      '交通': resolveNewId('交通出行>公共交通'),
      '购物': resolveNewId('住宅家居>家居用品'),
      '居住': resolveNewId('住宅家居>租金贷款'),
      '娱乐': resolveNewId('休闲娱乐>电影演出'),
      '医疗': resolveNewId('医疗健康>检查治疗'),
      '教育': resolveNewId('教育学习>培训课程'),
      '其他': resolveNewId('其他杂项>其他支出'),
    };

    final legacyIncomeMap = {
      '工资': resolveNewId('职业收入>工资收入'),
      '奖金': resolveNewId('职业收入>奖金收入'),
      '理财': resolveNewId('金融投资>投资收入'),
      '其他': resolveNewId('其他杂项>其他收入'),
    };

    for (final row in rows) {
      final oldId = row['id'] as int?;
      final name = row['name'] as String?;
      final type = row['type'] as int?;
      if (oldId == null || name == null || type == null) continue;

      int? newId;
      if (name == '转账') {
        newId = resolveNewId('一般转账>银行转账') ?? resolveNewId('一般转账');
      } else if (type == CategoryType.expense.value) {
        newId = legacyExpenseMap[name];
      } else if (type == CategoryType.income.value) {
        newId = legacyIncomeMap[name];
      }

      if (newId == null) continue;
      await db.update(
        'transactions',
        {'category_id': newId},
        where: 'category_id = ?',
        whereArgs: [oldId],
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    for (final row in rows) {
      await db.update(
        'categories',
        {
          'deleted_at': now,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  static Future<void> _seedType(
    Database db,
    CategoryType type,
    List<DefaultCategoryGroupPreset> groups,
  ) async {
    for (var rootIndex = 0; rootIndex < groups.length; rootIndex++) {
      final group = groups[rootIndex];
      final now = DateTime.now();
      final rootId = await db.insert(
        'categories',
        Category(
          uuid: _uuid.v4(),
          name: group.name,
          type: type,
          icon: group.icon,
          sortOrder: rootIndex,
          createdAt: now,
          updatedAt: now,
        ).toMap(),
      );

      for (var childIndex = 0; childIndex < group.children.length; childIndex++) {
        final child = group.children[childIndex];
        await db.insert(
          'categories',
          Category(
            uuid: _uuid.v4(),
            parentId: rootId,
            name: child.name,
            type: type,
            icon: child.icon,
            sortOrder: childIndex,
            createdAt: now,
            updatedAt: now,
          ).toMap(),
        );
      }
    }
  }
}
