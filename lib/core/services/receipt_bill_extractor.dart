import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/ocr_text_line.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/amount_keyword_rules.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/confidence_rules.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/merchant_extraction_rules.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/type_detection_rules.dart';
import 'package:ezbookkeeping_desktop/core/services/receipt_category_classifier.dart';
import 'package:ezbookkeeping_desktop/core/services/receipt_ocr_text_corrector.dart';

/// 小票/发票结构化提取结果
class ReceiptBillExtraction {
  const ReceiptBillExtraction({
    required this.amountCents,
    required this.type,
    this.merchant,
    this.date,
    this.primaryCategory,
    this.secondaryCategory,
    this.appCategoryName,
    this.remarks,
    this.confidence = 0.7,
    this.lowConfidence = false,
    this.amountLineIndex,
  });

  final int amountCents;
  final TransactionType type;
  final String? merchant;
  final DateTime? date;
  final String? primaryCategory;
  final String? secondaryCategory;
  final String? appCategoryName;
  final String? remarks;
  final double confidence;
  final bool lowConfidence;
  final int? amountLineIndex;
}

/// 购物小票 / 发票 / 通用票据字段提取（规则 4.x）
class ReceiptBillExtractor {
  const ReceiptBillExtractor({
    ReceiptOcrTextCorrector? ocrCorrector,
    ReceiptCategoryClassifier? categoryClassifier,
  })  : _ocrCorrector = ocrCorrector ?? const ReceiptOcrTextCorrector(),
        _categoryClassifier =
            categoryClassifier ?? const ReceiptCategoryClassifier();

  final ReceiptOcrTextCorrector _ocrCorrector;
  final ReceiptCategoryClassifier _categoryClassifier;

  ReceiptBillExtraction? extract(List<OcrTextLine> lines, {String? rawText}) {
    if (lines.isEmpty) return null;

    final normalized = lines
        .map(
          (line) => OcrTextLine(
            text: _ocrCorrector.apply(line.text),
            confidence: line.confidence,
            boundingBox: line.boundingBox,
            index: line.index,
          ),
        )
        .toList(growable: false);

    final amountResult = _extractAmount(normalized);
    if (amountResult == null) return null;

    final merchant = _extractMerchant(normalized);
    final date = _extractDate(normalized, rawText);
    final type = _extractType(normalized, amountResult.lineIndex);
    final category = _categoryClassifier.classify(
      merchant: merchant,
      transactionType: type,
    );

    var confidence = 0.55;
    if (amountResult.fromKeyword) confidence += 0.2;
    if (merchant != null) confidence += 0.1;
    if (date != null) confidence += 0.08;
    if (category.primary != null) confidence += 0.07;
    confidence = confidence.clamp(0.0, 1.0);

    final lowConfidence = amountResult.lineConfidence <
            kReceiptAmountLineConfidenceMin ||
        confidence < kReceiptOverallConfidenceLow;

    return ReceiptBillExtraction(
      amountCents: amountResult.cents,
      type: type,
      merchant: merchant,
      date: date,
      primaryCategory: category.primary,
      secondaryCategory: category.secondary,
      appCategoryName: category.appCategory,
      remarks: _buildRemarks(normalized, merchant, lowConfidence),
      confidence: confidence,
      lowConfidence: lowConfidence,
      amountLineIndex: amountResult.lineIndex,
    );
  }

  _AmountResult? _extractAmount(List<OcrTextLine> lines) {
    final sortedKeywords = [...kReceiptAmountKeywordRules]
      ..sort((a, b) => b.priority.compareTo(a.priority));

    for (final rule in sortedKeywords) {
      for (final line in lines) {
        if (!line.text.contains(rule.keyword)) continue;
        if (_isExcludedAmountLine(line.text)) continue;
        final amounts = _parseAmountsFromLine(line.text);
        if (amounts.isEmpty) continue;
        final cents = _pickBestAmount(amounts);
        if (cents != null) {
          return _AmountResult(
            cents: cents,
            lineIndex: line.index,
            lineConfidence: line.confidence,
            fromKeyword: true,
          );
        }
      }
    }

    final candidates = <_AmountCandidate>[];
    final maxBottom = lines.map((l) => l.bottom).reduce((a, b) => a > b ? a : b);

    for (final line in lines) {
      if (_isExcludedAmountLine(line.text)) continue;
      for (final yuan in _parseAmountsFromLine(line.text)) {
        if (yuan < kReceiptAmountMinYuan || yuan > kReceiptAmountMaxYuan) {
          continue;
        }
        candidates.add(
          _AmountCandidate(
            cents: (yuan * 100).round(),
            line: line,
            bottomScore: line.bottom / (maxBottom == 0 ? 1 : maxBottom),
          ),
        );
      }
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final height = b.line.height.compareTo(a.line.height);
      if (height != 0) return height;
      final bottom = b.bottomScore.compareTo(a.bottomScore);
      if (bottom != 0) return bottom;
      return b.line.confidence.compareTo(a.line.confidence);
    });

    final best = candidates.first;
    return _AmountResult(
      cents: best.cents,
      lineIndex: best.line.index,
      lineConfidence: best.line.confidence,
      fromKeyword: false,
    );
  }

  String? _extractMerchant(List<OcrTextLine> lines) {
    for (final line in lines) {
      for (final label in kReceiptMerchantLabelKeywords) {
        if (!line.text.contains(label)) continue;
        final value = _extractLabeledValue(line.text, label);
        if (value != null) return _cleanMerchant(value);
      }
    }

    final candidates = [...lines]
      ..sort((a, b) {
        final y = a.top.compareTo(b.top);
        if (y != 0) return y;
        return b.height.compareTo(a.height);
      });

    var checked = 0;
    for (final line in candidates) {
      if (checked >= kReceiptMerchantTopCandidateCount) break;
      if (_isNoiseMerchantLine(line.text)) continue;
      if (_looksLikeAmountOrDate(line.text)) continue;
      final name = _cleanMerchant(line.text);
      if (name != null) return name;
      checked++;
    }

    for (final line in lines) {
      if (_isNoiseMerchantLine(line.text)) continue;
      if (_looksLikeAmountOrDate(line.text)) continue;
      final name = _cleanMerchant(line.text);
      if (name != null) return name;
    }

    return null;
  }

  DateTime? _extractDate(List<OcrTextLine> lines, String? rawText) {
    final source = rawText ?? lines.map((l) => l.text).join('\n');
    final patterns = [
      RegExp(r'(\d{4})[-/.年](\d{1,2})[-/.月](\d{1,2})'),
      RegExp(r'(\d{4})-(\d{2})-(\d{2})'),
      RegExp(r'(\d{1,2})[-/.月](\d{1,2})[日号]?'),
    ];

    const dateLabels = ['日期', '时间', '开票日期', '交易日期', '打印时间'];

    for (final line in lines) {
      final hasLabel = dateLabels.any(line.text.contains);
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line.text);
        if (match == null) continue;
        final parsed = _parseDateMatch(match);
        if (parsed != null && (hasLabel || match.group(0)!.length >= 8)) {
          return parsed;
        }
      }
    }

    for (final pattern in patterns) {
      final match = pattern.firstMatch(source);
      if (match != null) {
        return _parseDateMatch(match);
      }
    }

    return null;
  }

  TransactionType _extractType(List<OcrTextLine> lines, int? amountLineIndex) {
    final fullText = lines.map((l) => l.text).join('\n');
    for (final keyword in kReceiptIncomeContextKeywords) {
      if (fullText.contains(keyword)) {
        return TransactionType.income;
      }
    }

    if (amountLineIndex != null) {
      final nearby = _contextAround(lines, amountLineIndex, radius: 2);
      for (final keyword in kReceiptIncomeContextKeywords) {
        if (nearby.contains(keyword)) {
          return TransactionType.income;
        }
      }
    }
    return TransactionType.expense;
  }

  String? _buildRemarks(
    List<OcrTextLine> lines,
    String? merchant,
    bool lowConfidence,
  ) {
    final parts = <String>[];
    if (lowConfidence) {
      parts.add('低置信度，建议核对金额与商户');
    }
    if (merchant != null) {
      parts.add('商户：$merchant');
    }
    if (parts.isEmpty) return null;
    return parts.join('；');
  }

  bool _isExcludedAmountLine(String text) {
    return kReceiptAmountExcludeLineKeywords.any(text.contains);
  }

  bool _isNoiseMerchantLine(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return true;
    return kReceiptMerchantNoisePrefixes.any(trimmed.startsWith);
  }

  bool _looksLikeAmountOrDate(String text) {
    if (RegExp(r'[¥$]\s*[\d,.]+').hasMatch(text)) return true;
    if (RegExp(r'^\d+([.,]\d{1,2})?$').hasMatch(text.trim())) return true;
    if (RegExp(r'\d{4}[-/.年]\d{1,2}').hasMatch(text)) return true;
    return false;
  }

  String? _extractLabeledValue(String line, String label) {
    final index = line.indexOf(label);
    if (index < 0) return null;
    var value = line.substring(index + label.length).trim();
    value = value.replaceFirst(RegExp(r'^[：:\s]+'), '');
    if (value.isEmpty) return null;
    return value;
  }

  String? _cleanMerchant(String raw) {
    var name = raw.trim();
    if (name.isEmpty) return null;
    name = name.replaceAll(RegExp(r'\s+'), '');
    name = name.replaceFirst(kReceiptMerchantBranchSuffixPattern, '');
    if (name.length < kReceiptMerchantMinLength ||
        name.length > kReceiptMerchantMaxLength) {
      return null;
    }
    return name;
  }

  List<double> _parseAmountsFromLine(String line) {
    final normalized = line
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('l', '1')
        .replaceAll('I', '1')
        .replaceAll('S', '5')
        .replaceAll('B', '8');

    final pattern = RegExp(
      r'[+-]?\s*[¥$]?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)',
    );
    final amounts = <double>[];
    for (final match in pattern.allMatches(normalized)) {
      final raw = match.group(1)?.replaceAll(',', '');
      if (raw == null) continue;
      final value = double.tryParse(raw.replaceAll('，', '.'));
      if (value != null) amounts.add(value);
    }
    return amounts;
  }

  int? _pickBestAmount(List<double> amounts) {
    if (amounts.isEmpty) return null;
    amounts.sort();
    final yuan = amounts.last;
    if (yuan < kReceiptAmountMinYuan || yuan > kReceiptAmountMaxYuan) {
      return null;
    }
    return (yuan * 100).round();
  }

  DateTime? _parseDateMatch(RegExpMatch match) {
    try {
      if (match.groupCount >= 3 && match.group(1)!.length == 4) {
        final y = int.parse(match.group(1)!);
        final m = int.parse(match.group(2)!);
        final d = int.parse(match.group(3)!);
        return DateTime(y, m, d);
      }
      if (match.groupCount >= 2) {
        final m = int.parse(match.group(1)!);
        final d = int.parse(match.group(2)!);
        final now = DateTime.now();
        var y = now.year;
        final candidate = DateTime(y, m, d);
        if (candidate.isAfter(now)) y -= 1;
        return DateTime(y, m, d);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _contextAround(List<OcrTextLine> lines, int index, {int radius = 2}) {
    final start = (index - radius).clamp(0, lines.length - 1);
    final end = (index + radius + 1).clamp(0, lines.length);
    return lines.sublist(start, end).map((l) => l.text).join('\n');
  }
}

class _AmountResult {
  const _AmountResult({
    required this.cents,
    required this.lineIndex,
    required this.lineConfidence,
    required this.fromKeyword,
  });

  final int cents;
  final int lineIndex;
  final double lineConfidence;
  final bool fromKeyword;
}

class _AmountCandidate {
  const _AmountCandidate({
    required this.cents,
    required this.line,
    required this.bottomScore,
  });

  final int cents;
  final OcrTextLine line;
  final double bottomScore;
}
