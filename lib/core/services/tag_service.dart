import 'package:ezbookkeeping_desktop/core/database/daos/tag_dao.dart';
import 'package:ezbookkeeping_desktop/core/models/tag.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_exception.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';
import 'package:uuid/uuid.dart';

class TagService {
  TagService(this._tagDao);

  final TagDao _tagDao;
  static const _uuid = Uuid();

  Future<Result<Tag>> createTag(String name, {String? color}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Result.failure(
        const AppException('标签名称不能为空', code: 'INVALID_NAME'),
      );
    }

    try {
      final now = DateTime.now();
      final tag = Tag(
        uuid: _uuid.v4(),
        name: trimmed,
        color: color,
        createdAt: now,
        updatedAt: now,
      );
      final id = await _tagDao.insert(tag);
      return Result.success(tag.copyWith(id: id));
    } catch (e, stack) {
      appLogger.e('创建标签失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('创建标签失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<Tag>> updateTag(Tag tag, String name, {String? color}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Result.failure(
        const AppException('标签名称不能为空', code: 'INVALID_NAME'),
      );
    }

    try {
      final updated = tag.copyWith(
        name: trimmed,
        color: color,
        updatedAt: DateTime.now(),
      );
      await _tagDao.update(updated);
      return Result.success(updated);
    } catch (e, stack) {
      appLogger.e('更新标签失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('更新标签失败', code: 'DB_ERROR'),
      );
    }
  }

  /// 按名称解析标签 ID；不存在则自动创建。
  Future<Result<List<int>>> resolveTagIds(Iterable<String> names) async {
    try {
      final ids = <int>[];
      final seen = <String>{};

      for (final raw in names) {
        final name = raw.trim();
        if (name.isEmpty) continue;
        final key = name.toLowerCase();
        if (seen.contains(key)) continue;
        seen.add(key);

        final existing = await _tagDao.findByName(name);
        if (existing?.id != null) {
          ids.add(existing!.id!);
          continue;
        }

        final deleted = await _tagDao.findByNameIncludingDeleted(name);
        if (deleted?.id != null && deleted!.deletedAt != null) {
          final now = DateTime.now();
          await _tagDao.restore(deleted.id!, now);
          ids.add(deleted.id!);
          continue;
        }

        final created = await createTag(name);
        final id = created.when(
          success: (tag) => tag.id,
          failure: (error) => throw error,
        );
        if (id != null) ids.add(id);
      }

      return Result.success(ids);
    } on AppException catch (error) {
      return Result.failure(error);
    } catch (e, stack) {
      appLogger.e('解析标签失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('解析标签失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<void>> deleteTag(int id) async {
    try {
      await _tagDao.purgeOrphanedTransactionLinks();
      final usage = await _tagDao.countUsage(id);
      if (usage > 0) {
        return Result.failure(
          AppException('该标签已被 $usage 笔交易使用，无法删除', code: 'IN_USE'),
        );
      }
      await _tagDao.softDelete(id, DateTime.now());
      return Result.success(null);
    } catch (e, stack) {
      appLogger.e('删除标签失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('删除标签失败', code: 'DB_ERROR'),
      );
    }
  }
}
