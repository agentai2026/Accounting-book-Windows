import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/income_category_rules.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/merchant_category_rules.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/receipt_category_keyword_rules.dart';

class ReceiptCategoryMatch {
  const ReceiptCategoryMatch({
    this.primary,
    this.secondary,
    required this.appCategory,
  });

  final String? primary;
  final String? secondary;
  final String appCategory;
}

/// 5.x 商户名 → 分类（关键词表 + 现有商户规则）
class ReceiptCategoryClassifier {
  const ReceiptCategoryClassifier();

  ReceiptCategoryMatch classify({
    required String? merchant,
    required TransactionType transactionType,
  }) {
    if (merchant == null || merchant.trim().isEmpty) {
      return ReceiptCategoryMatch(
        appCategory: transactionType == TransactionType.income
            ? kReceiptDefaultIncomeCategory
            : kReceiptDefaultExpenseCategory,
      );
    }

    final normalized = merchant.trim();

    ReceiptCategoryKeywordRule? best;
    var bestKeywordLength = 0;

    for (final rule in kReceiptCategoryKeywordRules) {
      for (final keyword in rule.keywords) {
        if (!normalized.contains(keyword)) continue;
        if (rule.priority > (best?.priority ?? -1) ||
            (rule.priority == best?.priority &&
                keyword.length > bestKeywordLength)) {
          best = rule;
          bestKeywordLength = keyword.length;
        }
      }
    }

    if (best != null) {
      return ReceiptCategoryMatch(
        primary: best.primary,
        secondary: best.secondary,
        appCategory: best.appCategory,
      );
    }

    if (transactionType == TransactionType.income) {
      for (final rule in kReceiptIncomeCategoryRules) {
        if (rule.keywords.any(normalized.contains)) {
          return ReceiptCategoryMatch(
            primary: '收入',
            appCategory: rule.category,
          );
        }
      }
      return const ReceiptCategoryMatch(
        primary: '收入',
        appCategory: kReceiptDefaultIncomeCategory,
      );
    }

    for (final rule in kReceiptMerchantCategoryRules) {
      if (rule.keywords.any(normalized.contains)) {
        return ReceiptCategoryMatch(
          primary: '其他',
          appCategory: rule.category,
        );
      }
    }

    return const ReceiptCategoryMatch(
      primary: '其他',
      appCategory: kReceiptDefaultExpenseCategory,
    );
  }
}
