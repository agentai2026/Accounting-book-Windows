import 'package:ezbookkeeping_desktop/core/constants/default_account_presets.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/account_dao.dart';
import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_exception.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';
import 'package:uuid/uuid.dart';

class AccountService {
  AccountService(this._accountDao);

  final AccountDao _accountDao;
  static const _uuid = Uuid();

  Future<Result<Account>> createAccount({
    required int bookId,
    required String name,
    required AccountType type,
    int initialBalanceCents = 0,
    String currency = 'CNY',
    String? icon,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Result.failure(
        const AppException('账户名称不能为空', code: 'INVALID_NAME'),
      );
    }

    try {
      final now = DateTime.now();
      final sortOrder =
          await _accountDao.maxSortOrder(bookId: bookId) + 1;
      final account = Account(
        uuid: _uuid.v4(),
        bookId: bookId,
        name: trimmed,
        type: type,
        balance: initialBalanceCents,
        currency: currency,
        icon: icon,
        sortOrder: sortOrder,
        createdAt: now,
        updatedAt: now,
      );
      final id = await _accountDao.insert(account);
      return Result.success(account.copyWith(id: id));
    } catch (e, stack) {
      appLogger.e('创建账户失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('创建账户失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<Account>> updateAccount({
    required Account account,
    required String name,
    required AccountType type,
    String? currency,
    String? icon,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Result.failure(
        const AppException('账户名称不能为空', code: 'INVALID_NAME'),
      );
    }

    try {
      final now = DateTime.now();
      final updated = account.copyWith(
        name: trimmed,
        type: type,
        currency: currency ?? account.currency,
        icon: icon ?? account.icon,
        updatedAt: now,
      );
      await _accountDao.update(updated);
      return Result.success(updated);
    } catch (e, stack) {
      appLogger.e('更新账户失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('更新账户失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<int>> createPresetAccounts({
    required int bookId,
    required List<DefaultAccountPreset> presets,
    Set<String> existingNames = const {},
  }) async {
    if (presets.isEmpty) {
      return Result.failure(
        const AppException('请至少选择一个账户', code: 'EMPTY_SELECTION'),
      );
    }

    try {
      var sortOrder = await _accountDao.maxSortOrder(bookId: bookId);
      var created = 0;
      final now = DateTime.now();
      final skipNames = Set<String>.from(existingNames);

      for (final preset in presets) {
        if (skipNames.contains(preset.name)) continue;

        sortOrder += 1;
        final account = Account(
          uuid: _uuid.v4(),
          bookId: bookId,
          name: preset.name,
          type: preset.type,
          balance: 0,
          currency: preset.currency,
          icon: preset.icon,
          sortOrder: sortOrder,
          createdAt: now,
          updatedAt: now,
        );
        await _accountDao.insert(account);
        skipNames.add(preset.name);
        created += 1;
      }

      if (created == 0) {
        return Result.failure(
          const AppException('所选账户均已存在', code: 'ALREADY_EXISTS'),
        );
      }

      return Result.success(created);
    } catch (e, stack) {
      appLogger.e('批量创建默认账户失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('创建默认账户失败', code: 'DB_ERROR'),
      );
    }
  }

  Future<Result<void>> deleteAccount(int id) async {
    try {
      final usage = await _accountDao.countUsage(id);
      if (usage > 0) {
        return Result.failure(
          AppException('该账户已有 $usage 笔关联交易，无法删除', code: 'IN_USE'),
        );
      }

      await _accountDao.softDelete(id, DateTime.now());
      return Result.success(null);
    } catch (e, stack) {
      appLogger.e('删除账户失败', error: e, stackTrace: stack);
      return Result.failure(
        const AppException('删除账户失败', code: 'DB_ERROR'),
      );
    }
  }
}
