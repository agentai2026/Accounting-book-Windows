import 'package:ezbookkeeping_desktop/core/ai/models/ocr_line.dart';
import 'package:ezbookkeeping_desktop/core/ai/normalize/ocr_correction_map.dart';
import 'package:ezbookkeeping_desktop/core/ai/normalize/text_normalizer.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/amount_keyword_rules.dart';

/// 金额提取结果
class AmountParseResult {
  const AmountParseResult({
    required this.amount,
    required this.lineIndex,
    required this.lineScore,
    required this.fromKeyword,
  });

  /// 元，保留两位小数
  final double amount;
  final int lineIndex;
  final double lineScore;
  final bool fromKeyword;
}

/// 从 OCR 行中提取交易金额（四层策略）
class AmountParser {
  const AmountParser({TextNormalizer? normalizer})
      : _normalizer = normalizer ?? const TextNormalizer();

  final TextNormalizer _normalizer;

  /// 提取金额；失败返回 null
  AmountParseResult? extractAmount(List<AiOcrLine> lines) {
    if (lines.isEmpty) return null;

    final layer1 = _extractByKeywords(lines);
    if (layer1 != null) return layer1;

    final layer2 = _extractByBottomPosition(lines);
    if (layer2 != null) return layer2;

    final layer3 = _extractByLargestFont(lines);
    if (layer3 != null) return layer3;

    return _extractByMaxValue(lines);
  }

  /// 第一层：关键词锚定
  AmountParseResult? _extractByKeywords(List<AiOcrLine> lines) {
    for (final keyword in kAmountPrimaryKeywords) {
      for (final line in lines) {
        if (!line.text.contains(keyword)) continue;
        if (_isExcludedLine(line.text)) continue;
        final amounts = _parseAmounts(line.text);
        final picked = _pickMaxValid(amounts);
        if (picked != null) {
          return AmountParseResult(
            amount: picked,
            lineIndex: line.index,
            lineScore: line.score,
            fromKeyword: true,
          );
        }
      }
    }
    return null;
  }

  /// 第二层：页面底部优先
  AmountParseResult? _extractByBottomPosition(List<AiOcrLine> lines) {
    final candidates = _collectCandidates(lines);
    if (candidates.isEmpty) return null;

    final maxBottom = lines.map((l) => l.bottom).reduce((a, b) => a > b ? a : b);
    candidates.sort((a, b) {
      final bottomA = a.line.bottom / maxBottom;
      final bottomB = b.line.bottom / maxBottom;
      return bottomB.compareTo(bottomA);
    });

    final best = candidates.first;
    return AmountParseResult(
      amount: best.amount,
      lineIndex: best.line.index,
      lineScore: best.line.score,
      fromKeyword: false,
    );
  }

  /// 第三层：最大字号（bbox 高度）
  AmountParseResult? _extractByLargestFont(List<AiOcrLine> lines) {
    final candidates = _collectCandidates(lines);
    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.line.height.compareTo(a.line.height));
    final best = candidates.first;
    return AmountParseResult(
      amount: best.amount,
      lineIndex: best.line.index,
      lineScore: best.line.score,
      fromKeyword: false,
    );
  }

  /// 第四层：最大金额值
  AmountParseResult? _extractByMaxValue(List<AiOcrLine> lines) {
    final candidates = _collectCandidates(lines);
    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.amount.compareTo(a.amount));
    final best = candidates.first;
    return AmountParseResult(
      amount: best.amount,
      lineIndex: best.line.index,
      lineScore: best.line.score,
      fromKeyword: false,
    );
  }

  List<_AmountCandidate> _collectCandidates(List<AiOcrLine> lines) {
    final result = <_AmountCandidate>[];
    for (final line in lines) {
      if (_isExcludedLine(line.text)) continue;
      for (final yuan in _parseAmounts(line.text)) {
        if (yuan < kReceiptAmountMinYuan || yuan > kReceiptAmountMaxYuan) {
          continue;
        }
        result.add(_AmountCandidate(amount: yuan, line: line));
      }
    }
    return result;
  }

  bool _isExcludedLine(String text) {
    return kReceiptAmountExcludeLineKeywords.any(text.contains);
  }

  List<double> _parseAmounts(String line) {
    final trimmed = line.trim();
    if (RegExp(r'^\d{1,2}\s*月').hasMatch(trimmed)) return [];
    if (trimmed.contains('无收支记录')) return [];

    final normalized = _normalizer.normalizeAmountLine(line);
    final pattern = RegExp(
      r'[+-]?\s*[¥$]?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)',
    );
    final amounts = <double>[];
    for (final match in pattern.allMatches(normalized)) {
      final raw = match.group(1)?.replaceAll(',', '').replaceAll('，', '.');
      if (raw == null) continue;
      if (_isLikelyYearOrHeaderNumber(raw, line)) continue;
      final value = double.tryParse(raw);
      if (value != null) amounts.add(value);
    }
    return amounts;
  }

  bool _isLikelyYearOrHeaderNumber(String raw, String line) {
    if (!raw.contains('.') && RegExp(r'^(19|20)\d{2}$').hasMatch(raw)) {
      return true;
    }
    return false;
  }

  double? _pickMaxValid(List<double> amounts) {
    if (amounts.isEmpty) return null;
    amounts.sort();
    final yuan = amounts.last;
    if (yuan < kReceiptAmountMinYuan || yuan > kReceiptAmountMaxYuan) {
      return null;
    }
    return double.parse(yuan.toStringAsFixed(2));
  }
}

class _AmountCandidate {
  const _AmountCandidate({required this.amount, required this.line});

  final double amount;
  final AiOcrLine line;
}
