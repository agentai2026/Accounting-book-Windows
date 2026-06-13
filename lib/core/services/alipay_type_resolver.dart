import 'package:ezbookkeeping_desktop/core/constants/bookkeeping_metrics_rules.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/label_utils.dart';

/// 解析支付宝 CSV「收/支」列，并结合「交易分类」兜底。
class AlipayTypeResolver {
  AlipayTypeResolver._();

  static const _neutralCategoryKeywords = [
    '投资理财',
    '转账红包',
    '转账',
    '红包',
    '信用卡',
    '信用卡还款',
    '余额宝',
    '花呗',
    '借呗',
    '基金',
    '理财',
    '零钱通',
    '提现',
    '充值',
  ];

  static TransactionType? resolve({
    required String? typeText,
    String? categoryName,
    String? status,
  }) {
    final text = typeText?.trim().replaceAll(' ', '') ?? '';
    if (text.isNotEmpty) {
      final parsed = _parseDirection(text);
      if (parsed != null) {
        if (parsed != TransactionType.transfer &&
            BookkeepingMetricsRules.countsAsNetTransfer(
              categoryName: categoryName,
              direction: typeText,
              status: status ?? '交易成功',
            )) {
          return TransactionType.transfer;
        }
        return parsed;
      }

      final neutralFallback = switch (text) {
        '其他' || '其它' || '无' => _isNeutralCategory(categoryName),
        _ => false,
      };
      if (neutralFallback) return TransactionType.transfer;

      if (_isNeutralCategory(categoryName)) {
        return TransactionType.transfer;
      }
      return null;
    }

    if (_isNeutralCategory(categoryName)) {
      return TransactionType.transfer;
    }
    return null;
  }

  static TransactionType? _parseDirection(String text) {
    for (final type in TransactionType.values) {
      if (transactionTypeLabel(type) == text) return type;
    }

    return switch (text) {
      '支出' => TransactionType.expense,
      '收入' => TransactionType.income,
      '转账' => TransactionType.transfer,
      '不计收支' || '不计入收支' => TransactionType.transfer,
      '中性' || '中性交易' || '/' => TransactionType.transfer,
      '其他' || '其它' || '无' => null,
      _ => null,
    };
  }

  static bool _isNeutralCategory(String? categoryName) {
    final category = categoryName?.trim() ?? '';
    if (category.isEmpty) return false;
    return _neutralCategoryKeywords.any(category.contains);
  }
}
