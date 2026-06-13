import 'package:ezbookkeeping_desktop/core/models/transaction.dart' as models;
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/dedup_rules.dart';

/// 六、重复账单检测
class ReceiptDuplicateChecker {
  const ReceiptDuplicateChecker();

  /// 返回 true 表示疑似重复
  bool isDuplicate({
    required int amountCents,
    required DateTime? date,
    required String? merchant,
    required String? ocrRawText,
    required List<models.Transaction> recentTransactions,
    required Map<int, String?> transactionDescriptions,
  }) {
    if (recentTransactions.isEmpty) return false;

    final merchantKey = merchant?.trim().toLowerCase() ?? '';
    final day = date != null
        ? DateTime(date.year, date.month, date.day)
        : null;

    for (final tx in recentTransactions) {
      if (tx.amountCents != amountCents) continue;

      if (day != null) {
        final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
        final diff = txDay.difference(day).inDays.abs();
        if (diff > kReceiptDedupExactWindowDays) continue;
      }

      final desc = transactionDescriptions[tx.id]?.toLowerCase() ?? '';
      if (merchantKey.isNotEmpty &&
          (desc.contains(merchantKey) || _sameMerchant(desc, merchantKey))) {
        return true;
      }

      if (ocrRawText != null &&
          desc.isNotEmpty &&
          _jaccardSimilarity(ocrRawText, desc) >=
              kReceiptDedupTextSimilarityThreshold) {
        return true;
      }
    }

    return false;
  }

  bool _sameMerchant(String desc, String merchantKey) {
    return desc.split(RegExp(r'\s+')).any((part) => part.contains(merchantKey));
  }

  double _jaccardSimilarity(String a, String b) {
    final setA = a.split(RegExp(r'\s+')).where((s) => s.length > 1).toSet();
    final setB = b.split(RegExp(r'\s+')).where((s) => s.length > 1).toSet();
    if (setA.isEmpty || setB.isEmpty) return 0;
    final intersection = setA.intersection(setB).length;
    final union = {...setA, ...setB}.length;
    return intersection / union;
  }
}
