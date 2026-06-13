import 'dart:convert';

import 'package:ezbookkeeping_desktop/core/ai/models/bill.dart';

/// 已有账单摘要（去重对比用）
class ExistingBillSummary {
  const ExistingBillSummary({
    required this.merchant,
    required this.amount,
    required this.date,
    this.time,
    this.rawText,
    this.recordedAt,
  });

  final String merchant;
  final double amount;
  final String date;
  final String? time;
  final String? rawText;
  final DateTime? recordedAt;
}

/// 去重检测结果
class DuplicateCheckResult {
  const DuplicateCheckResult({
    required this.isDuplicate,
    this.exactMatch = false,
    this.fuzzyMatch = false,
    this.similarity = 0,
  });

  final bool isDuplicate;
  final bool exactMatch;
  final bool fuzzyMatch;
  final double similarity;
}

/// 精确 + 模糊去重
class DuplicateChecker {
  const DuplicateChecker();

  /// 生成账单指纹 md5 风格 hash（本地 SHA256 前 16 位）
  String buildHash({
    required String merchant,
    required double amount,
    required String date,
  }) {
    final key =
        '${merchant.trim().toLowerCase()}|${amount.toStringAsFixed(2)}|$date';
    final bytes = utf8.encode(key);
    var hash = 0;
    for (final byte in bytes) {
      hash = 0x1fffffff & (hash + byte);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= hash >> 11;
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// 检查是否与已有账单重复
  DuplicateCheckResult checkDuplicate({
    required Bill candidate,
    required List<ExistingBillSummary> existing,
    String? ocrRawText,
  }) {
    for (final item in existing) {
      if (_exactMatch(candidate, item)) {
        return const DuplicateCheckResult(
          isDuplicate: true,
          exactMatch: true,
          similarity: 1,
        );
      }
    }

    for (final item in existing) {
      if (candidate.amount != item.amount) continue;

      final similarity = _textSimilarity(
        ocrRawText ?? candidate.merchant,
        item.rawText ?? item.merchant,
      );

      if (similarity > 0.9 && _withinTenMinutes(candidate, item)) {
        return DuplicateCheckResult(
          isDuplicate: true,
          fuzzyMatch: true,
          similarity: similarity,
        );
      }
    }

    return const DuplicateCheckResult(isDuplicate: false);
  }

  bool _exactMatch(Bill candidate, ExistingBillSummary item) {
    return candidate.merchant.trim().toLowerCase() ==
            item.merchant.trim().toLowerCase() &&
        candidate.amount.toStringAsFixed(2) ==
            item.amount.toStringAsFixed(2) &&
        candidate.date == item.date;
  }

  bool _withinTenMinutes(Bill candidate, ExistingBillSummary item) {
    if (candidate.time == null || item.time == null || item.recordedAt == null) {
      return candidate.date == item.date;
    }

    try {
      final parts = candidate.time!.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final dateParts = candidate.date.split('-');
      final dt = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        h,
        m,
      );
      final diff = dt.difference(item.recordedAt!).inMinutes.abs();
      return diff < 10;
    } catch (_) {
      return candidate.date == item.date;
    }
  }

  /// Levenshtein 相似度 0~1
  double _textSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;
    final distance = _levenshtein(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    return 1 - distance / maxLen;
  }

  int _levenshtein(String a, String b) {
    final m = a.length;
    final n = b.length;
    if (m == 0) return n;
    if (n == 0) return m;

    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= n; j++) {
      dp[0][j] = j;
    }

    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((v, e) => v < e ? v : e);
      }
    }
    return dp[m][n];
  }
}
