import 'package:ezbookkeeping_desktop/core/ai/models/bill.dart';
import 'package:ezbookkeeping_desktop/core/ai/parser/amount_parser.dart';
import 'package:ezbookkeeping_desktop/core/ai/parser/date_parser.dart';

/// 各字段得分明细
class ConfidenceBreakdown {
  const ConfidenceBreakdown({
    required this.amountScore,
    required this.merchantScore,
    required this.dateScore,
    required this.categoryScore,
  });

  final double amountScore;
  final double merchantScore;
  final double dateScore;
  final double categoryScore;

  double get total =>
      amountScore + merchantScore + dateScore + categoryScore;
}

/// 置信度评分（满分 100）
class ConfidenceScorer {
  const ConfidenceScorer();

  static const amountWeight = 40.0;
  static const merchantWeight = 20.0;
  static const dateWeight = 20.0;
  static const categoryWeight = 20.0;

  /// 计算总分及入账级别
  ConfidenceBreakdown score({
    required AmountParseResult? amount,
    required String merchant,
    required DateParseResult? date,
    required bool categoryMatched,
  }) {
    final amountScore = amount == null
        ? 0.0
        : amountWeight *
            (amount.fromKeyword
                ? 1.0
                : (amount.lineScore >= 0.7 ? 0.85 : 0.6));

    final merchantScore = merchant.trim().isEmpty
        ? 0.0
        : merchant.length >= 2
            ? merchantWeight
            : merchantWeight * 0.5;

    final dateScore = date == null
        ? 0.0
        : date.hasFullDate
            ? dateWeight
            : dateWeight * 0.7;

    final categoryScore =
        categoryMatched ? categoryWeight : categoryWeight * 0.4;

    return ConfidenceBreakdown(
      amountScore: amountScore,
      merchantScore: merchantScore,
      dateScore: dateScore,
      categoryScore: categoryScore,
    );
  }

  /// >=85 自动入账；70~84 确认；<70 手动
  BillAutoEntryLevel entryLevel(double totalScore) {
    if (totalScore >= 85) return BillAutoEntryLevel.auto;
    if (totalScore >= 70) return BillAutoEntryLevel.confirm;
    return BillAutoEntryLevel.manual;
  }
}
