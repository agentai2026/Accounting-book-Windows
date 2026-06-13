import 'package:ezbookkeeping_desktop/core/ai/models/bill.dart';
import 'package:ezbookkeeping_desktop/core/ai/models/ocr_line.dart';
import 'package:ezbookkeeping_desktop/core/ai/normalize/ocr_correction_map.dart';

/// 交易类型识别：支出 / 收入 / 转账
class TypeParser {
  const TypeParser();

  /// [amountLineIndex] 金额所在行，用于上下文判断
  BillType extractType(List<AiOcrLine> lines, {int? amountLineIndex}) {
    final fullText = lines.map((line) => line.text).join('\n');

    if (_isTransferLabelOnly(fullText)) {
      return _resolveWithoutTransferKeywords(fullText, lines, amountLineIndex);
    }

    for (final keyword in kTransferTypeKeywords) {
      if (fullText.contains(keyword)) {
        if (RegExp(r'^转账[-—]').hasMatch(fullText.split('\n').join(' '))) {
          return BillType.income;
        }
        return BillType.transfer;
      }
    }

    if (RegExp(r'^转账[-—]').hasMatch(fullText.split('\n').first)) {
      return BillType.income;
    }

    return _resolveWithoutTransferKeywords(fullText, lines, amountLineIndex);
  }

  BillType _resolveWithoutTransferKeywords(
    String fullText,
    List<AiOcrLine> lines,
    int? amountLineIndex,
  ) {
    final signedLineType = _typeFromStandaloneSignedAmountLine(lines);
    if (signedLineType != null) return signedLineType;

    for (final keyword in kIncomeTypeKeywords) {
      if (fullText.contains(keyword)) return BillType.income;
    }

    if (amountLineIndex != null) {
      final nearby = _contextAround(lines, amountLineIndex);
      for (final keyword in kIncomeTypeKeywords) {
        if (nearby.contains(keyword)) return BillType.income;
      }
      if (RegExp(r'[+\＋]\s*¥?\s*[\d,]').hasMatch(nearby)) {
        return BillType.income;
      }
      if (RegExp(r'[-－]\s*¥?\s*[\d,]').hasMatch(nearby)) {
        return BillType.expense;
      }
    }

    return BillType.expense;
  }

  bool _isTransferLabelOnly(String text) {
    return kTransferLabelOnlyKeywords.any(text.contains) &&
        !kTransferTypeKeywords.any(text.contains);
  }

  String _contextAround(List<AiOcrLine> lines, int index, {int radius = 2}) {
    final start = (index - radius).clamp(0, lines.length - 1);
    final end = (index + radius + 1).clamp(0, lines.length);
    return lines.sublist(start, end).map((l) => l.text).join('\n');
  }

  /// 整行带符号金额（如 -400.30）优先于全文关键词
  BillType? _typeFromStandaloneSignedAmountLine(List<AiOcrLine> lines) {
    final pattern = RegExp(r'^[-－+＋]\s*[\d,\s]+(?:\.\d{1,2})?$');
    for (final line in lines) {
      final trimmed = line.text.trim();
      if (!pattern.hasMatch(trimmed)) continue;
      if (trimmed.startsWith('-') || trimmed.startsWith('－')) {
        return BillType.expense;
      }
      if (trimmed.startsWith('+') || trimmed.startsWith('＋')) {
        return BillType.income;
      }
    }
    return null;
  }
}

/// AI 识图入口：强制支出/收入
BillType coerceForAiRecognition(BillType type) {
  return switch (type) {
    BillType.transfer => BillType.expense,
    BillType.expense => BillType.expense,
    BillType.income => BillType.income,
  };
}

/// 银行转账行 + 正金额 → 收入
BillType normalizeBankTransferType(List<AiOcrLine> lines, BillType type) {
  final text = lines.map((l) => l.text).join('\n');
  if (type == BillType.transfer &&
      lines.any((l) => RegExp(r'^转账[-—]').hasMatch(l.text))) {
    if (RegExp(r'[+\＋]').hasMatch(text)) return BillType.income;
  }
  return type;
}
