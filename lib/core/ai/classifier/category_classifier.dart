import 'package:ezbookkeeping_desktop/core/ai/classifier/category_rules.dart';
import 'package:ezbookkeeping_desktop/core/ai/models/bill.dart';

/// 分类预测结果
class CategoryClassifyResult {
  const CategoryClassifyResult({
    required this.category,
    required this.appCategory,
    this.primaryCategory,
    this.secondaryCategory,
    this.matchedBy = CategoryMatchSource.defaultFallback,
  });

  final String category;
  final String appCategory;
  final String? primaryCategory;
  final String? secondaryCategory;
  final CategoryMatchSource matchedBy;
}

enum CategoryMatchSource {
  merchantExact,
  keywordContains,
  aiModel,
  defaultFallback,
}

/// 本地 AI 分类器接口（fastText / 大模型预留）
abstract class AiCategoryPredictor {
  /// 根据商户名预测一级分类；未实现时返回 null
  Future<String?> predictByAI(String merchant);
}

/// 空实现：后续接入 fastText
class StubAiCategoryPredictor implements AiCategoryPredictor {
  const StubAiCategoryPredictor();

  @override
  Future<String?> predictByAI(String merchant) async => null;
}

/// 自动分类：商户库精确匹配 → 关键词 → AI 兜底
class CategoryClassifier {
  CategoryClassifier({AiCategoryPredictor? aiPredictor})
      : _aiPredictor = aiPredictor ?? const StubAiCategoryPredictor();

  final AiCategoryPredictor _aiPredictor;

  /// 同步分类（关键词 + 商户库）
  CategoryClassifyResult classifyCategory({
    required String merchant,
    required BillType type,
  }) {
    final normalized = merchant.trim();
    if (normalized.isNotEmpty) {
      for (final entry in kMerchantDatabase.entries) {
        if (normalized == entry.key) {
          return _fromPrimary(entry.value, CategoryMatchSource.merchantExact);
        }
      }

      CategoryRuleEntry? best;
      var bestLen = 0;
      for (final rule in kCategoryRules) {
        for (final keyword in rule.keywords) {
          if (!normalized.contains(keyword)) continue;
          if (rule.priority > (best?.priority ?? -1) ||
              (rule.priority == best?.priority && keyword.length > bestLen)) {
            best = rule;
            bestLen = keyword.length;
          }
        }
      }
      if (best != null) {
        return CategoryClassifyResult(
          category: best.category,
          appCategory: best.appCategory,
          primaryCategory: best.category,
          matchedBy: CategoryMatchSource.keywordContains,
        );
      }
    }

    if (type == BillType.income) {
      return const CategoryClassifyResult(
        category: kDefaultCategory,
        appCategory: '其他收入',
        primaryCategory: '收入',
        matchedBy: CategoryMatchSource.defaultFallback,
      );
    }

    return const CategoryClassifyResult(
      category: kDefaultCategory,
      appCategory: '其他支出',
      primaryCategory: kDefaultCategory,
      matchedBy: CategoryMatchSource.defaultFallback,
    );
  }

  /// 异步分类（含 AI 模型）
  Future<CategoryClassifyResult> classifyCategoryAsync({
    required String merchant,
    required BillType type,
  }) async {
    final ruleResult = classifyCategory(merchant: merchant, type: type);
    if (ruleResult.matchedBy != CategoryMatchSource.defaultFallback) {
      return ruleResult;
    }

    final aiCategory = await _aiPredictor.predictByAI(merchant);
    if (aiCategory != null) {
      return _fromPrimary(aiCategory, CategoryMatchSource.aiModel);
    }

    return ruleResult;
  }

  CategoryClassifyResult _fromPrimary(
    String primary,
    CategoryMatchSource source,
  ) {
    for (final rule in kCategoryRules) {
      if (rule.category == primary) {
        return CategoryClassifyResult(
          category: rule.category,
          appCategory: rule.appCategory,
          primaryCategory: primary,
          matchedBy: source,
        );
      }
    }
    return CategoryClassifyResult(
      category: primary,
      appCategory: '其他支出',
      primaryCategory: primary,
      matchedBy: source,
    );
  }
}
