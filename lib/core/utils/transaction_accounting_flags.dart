import 'package:ezbookkeeping_desktop/core/constants/bookkeeping_metrics_rules.dart';
import 'package:ezbookkeeping_desktop/core/constants/transaction_flag_tags.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/transaction.dart';
import 'package:ezbookkeeping_desktop/core/services/transfer_metrics_calculator.dart';
import 'package:ezbookkeeping_desktop/core/utils/import_source_metadata.dart';

/// 账单是否计入收支/预算（与统计规则一致，供详情展示）
class TransactionAccountingFlags {
  TransactionAccountingFlags._();

  static bool excludesFromIncomeExpense(
    Transaction transaction, {
    Set<String> tagNames = const {},
  }) {
    if (tagNames.contains(TransactionFlagTags.excludeFromIo)) return true;
    if (transaction.type == TransactionType.transfer) return true;

    final meta = ImportSourceMetadata.parse(transaction.comment);
    if (meta == null) return false;

    final direction =
        meta.direction ?? TransferMetricsCalculator.directionFromType(transaction.type);
    final status = meta.status ?? '交易成功';
    final category = meta.categoryName ?? '';

    if (BookkeepingMetricsRules.isNeutralFlow(direction: direction)) {
      return true;
    }

    return !BookkeepingMetricsRules.countsInExpenseTotal(
          categoryName: category,
          direction: direction,
          status: status,
        ) &&
        !BookkeepingMetricsRules.countsInIncomeTotal(
          categoryName: category,
          direction: direction,
          status: status,
        );
  }

  /// 是否由导入元数据决定「不计入收支」（用户无法在详情里直接取消）
  static bool isImportMetadataIoExcluded(Transaction transaction) {
    if (transaction.type == TransactionType.transfer) return true;
    final meta = ImportSourceMetadata.parse(transaction.comment);
    if (meta == null) return false;

    final direction =
        meta.direction ?? TransferMetricsCalculator.directionFromType(transaction.type);
    final status = meta.status ?? '交易成功';
    final category = meta.categoryName ?? '';

    if (BookkeepingMetricsRules.isNeutralFlow(direction: direction)) return true;

    return !BookkeepingMetricsRules.countsInExpenseTotal(
          categoryName: category,
          direction: direction,
          status: status,
        ) &&
        !BookkeepingMetricsRules.countsInIncomeTotal(
          categoryName: category,
          direction: direction,
          status: status,
        );
  }

  /// [budgetCategoryIds] 当前账本已设预算的分类 id；空集合表示未设分类预算。
  static bool excludesFromBudget(
    Transaction transaction, {
    required Set<int> budgetCategoryIds,
    Set<String> tagNames = const {},
  }) {
    if (tagNames.contains(TransactionFlagTags.excludeFromBudget)) return true;
    if (transaction.type != TransactionType.expense) return true;
    if (budgetCategoryIds.isEmpty) return false;
    return !budgetCategoryIds.contains(transaction.categoryId);
  }

  /// 支出分类是否在预算跟踪范围内（可手动标记「不计入预算」）
  static bool canToggleBudgetFlag(
    Transaction transaction, {
    required Set<int> budgetCategoryIds,
  }) {
    if (transaction.type != TransactionType.expense) return false;
    if (budgetCategoryIds.isEmpty) return true;
    return budgetCategoryIds.contains(transaction.categoryId);
  }
}
