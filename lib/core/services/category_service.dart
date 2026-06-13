import 'package:ezbookkeeping_desktop/core/constants/default_category_presets.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/category_dao.dart';
import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_exception.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';
import 'package:uuid/uuid.dart';

class CategoryService {
  CategoryService(this._categoryDao);

  final CategoryDao _categoryDao;
  static const _uuid = Uuid();

  Future<Result<Category>> createCategory({
    required String name,
    required CategoryType type,
    int? parentId,
    String? icon,
    String? color,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Result.failure(
        const AppException('分类名称不能为空', code: 'INVALID_NAME'),
      );
    }

    if (parentId != null) {
      final parent = await _categoryDao.getById(parentId);
      if (parent == null) {
        return Result.failure(
          const AppException('父分类不存在', code: 'NOT_FOUND'),
        );
      }
      if (parent.type != type) {
        return Result.failure(
          const AppException('子分类类型必须与父分类一致', code: 'INVALID_TYPE'),
        );
      }
    }

    try {
      final now = DateTime.now();
      final sortOrder = await _categoryDao.maxSortOrder(
            type: type,
            parentId: parentId,
          ) +
          1;
      final category = Category(
        uuid: _uuid.v4(),
        parentId: parentId,
        name: trimmed,
        type: type,
        icon: icon,
        color: color,
        sortOrder: sortOrder,
        createdAt: now,
        updatedAt: now,
      );
      final id = await _categoryDao.insert(category);
      return Result.success(category.copyWith(id: id));
    } catch (e, stack) {
      appLogger.e('创建分类失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('创建分类失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<Category>> updateCategory({
    required Category category,
    required String name,
    int? parentId,
    String? icon,
    String? color,
  }) async {
    if (_isSystemCategory(category)) {
      return Result.failure(
        const AppException('系统分类不可编辑', code: 'SYSTEM_CATEGORY'),
      );
    }

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Result.failure(
        const AppException('分类名称不能为空', code: 'INVALID_NAME'),
      );
    }

    if (parentId == category.id) {
      return Result.failure(
        const AppException('不能将分类设为自己的子分类', code: 'INVALID_PARENT'),
      );
    }

    try {
      final now = DateTime.now();
      final updated = category.copyWith(
        name: trimmed,
        parentId: parentId,
        icon: icon,
        color: color,
        updatedAt: now,
        clearParentId: parentId == null,
      );
      await _categoryDao.update(updated);
      return Result.success(updated);
    } catch (e, stack) {
      appLogger.e('更新分类失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('更新分类失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<int>> createPresetCategoryGroups({
    required CategoryType type,
    required List<DefaultCategoryGroupPreset> groups,
    Set<String> existingRootNames = const {},
  }) async {
    if (groups.isEmpty) {
      return Result.failure(
        const AppException('请至少选择一个分类组', code: 'EMPTY_SELECTION'),
      );
    }

    try {
      var rootSortOrder = await _categoryDao.maxSortOrder(type: type, parentId: null);
      var createdGroups = 0;
      final skipNames = Set<String>.from(existingRootNames);
      final now = DateTime.now();

      for (final group in groups) {
        if (skipNames.contains(group.name)) continue;

        rootSortOrder += 1;
        final root = Category(
          uuid: _uuid.v4(),
          name: group.name,
          type: type,
          icon: group.icon,
          sortOrder: rootSortOrder,
          createdAt: now,
          updatedAt: now,
        );
        final rootId = await _categoryDao.insert(root);

        for (var childIndex = 0; childIndex < group.children.length; childIndex++) {
          final child = group.children[childIndex];
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

        skipNames.add(group.name);
        createdGroups += 1;
      }

      if (createdGroups == 0) {
        return Result.failure(
          const AppException('所选分类均已存在', code: 'ALREADY_EXISTS'),
        );
      }

      return Result.success(createdGroups);
    } catch (e, stack) {
      appLogger.e('批量创建默认分类失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('创建默认分类失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<void>> deleteCategory(int id) async {
    try {
      final category = await _categoryDao.getById(id);
      if (category == null) {
        return Result.failure(
          const AppException('分类不存在', code: 'NOT_FOUND'),
        );
      }
      if (_isSystemCategory(category)) {
        return Result.failure(
          const AppException('系统分类不可删除', code: 'SYSTEM_CATEGORY'),
        );
      }

      final usage = await _categoryDao.countUsage(id);
      if (usage > 0) {
        return Result.failure(
          AppException('该分类已有 $usage 笔关联交易，无法删除', code: 'IN_USE'),
        );
      }

      final childCount = await _categoryDao.countChildren(id);
      if (childCount > 0) {
        return Result.failure(
          AppException('请先删除 $childCount 个子分类', code: 'HAS_CHILDREN'),
        );
      }

      await _categoryDao.softDelete(id, DateTime.now());
      return Result.success(null);
    } catch (e, stack) {
      appLogger.e('删除分类失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('删除分类失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<void>> reorderCategories(List<int> orderedIds) async {
    if (orderedIds.isEmpty) {
      return Result.success(null);
    }

    try {
      await _categoryDao.updateSortOrders(orderedIds);
      return Result.success(null);
    } catch (e, stack) {
      appLogger.e('分类排序失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('分类排序失败', code: 'DB_ERROR'),
      );
    }
  }

  bool _isSystemCategory(Category category) {
    return category.type == CategoryType.transfer && category.parentId == null;
  }
}
