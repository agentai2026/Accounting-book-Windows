import 'package:ezbookkeeping_desktop/core/ai/models/ocr_line.dart';
import 'package:ezbookkeeping_desktop/core/ai/normalize/ocr_correction_map.dart';
import 'package:ezbookkeeping_desktop/core/rules/ai_recognition/merchant_extraction_rules.dart';

/// 商户名提取
class MerchantParser {
  const MerchantParser();

  /// 提取商户名；失败返回空字符串
  String extractMerchant(List<AiOcrLine> lines) {
    if (lines.isEmpty) return '';

    final byLabel = _extractByLabel(lines);
    if (byLabel != null) return byLabel;

    final nearPayment = _extractNearPaymentKeyword(lines);
    if (nearPayment != null) return nearPayment;

    final topRegion = _extractFromTopRegion(lines);
    if (topRegion != null) return topRegion;

    return _extractByScan(lines) ?? '';
  }

  /// 实付/应付 上方通常是店名（纸质小票）
  String? _extractNearPaymentKeyword(List<AiOcrLine> lines) {
    final sorted = [...lines]..sort((a, b) => a.top.compareTo(b.top));
    for (var i = 0; i < sorted.length; i++) {
      final text = sorted[i].text;
      if (!text.contains('实付') &&
          !text.contains('应付') &&
          !text.contains('结账单')) {
        continue;
      }
      for (var j = i - 1; j >= 0 && j >= i - 8; j--) {
        final candidate = sorted[j].text;
        if (_isNoise(candidate)) continue;
        if (_looksLikeAmountOrDate(candidate)) continue;
        if (_isReceiptMetaLine(candidate)) continue;
        final name = _clean(candidate);
        if (name != null && name.length >= 3) return name;
      }
    }
    return null;
  }

  bool _isReceiptMetaLine(String text) {
    const keywords = [
      '取单号',
      '订单编号',
      '下单时间',
      '结账时间',
      '收银员',
      '合计',
      '小计',
      '总计',
      '原价',
      '数量',
      '金额',
    ];
    return keywords.any(text.contains);
  }

  /// 标签行：商户名称 / 收款方 等
  String? _extractByLabel(List<AiOcrLine> lines) {
    for (final line in lines) {
      for (final label in kMerchantLabelKeywords) {
        if (!line.text.contains(label)) continue;
        final value = _valueAfterLabel(line.text, label);
        if (value != null) return _clean(value);
      }
    }
    return null;
  }

  /// 页面顶部 20% 区域 + 最大字号
  String? _extractFromTopRegion(List<AiOcrLine> lines) {
    final maxBottom = lines.map((l) => l.bottom).reduce((a, b) => a > b ? a : b);
    final threshold = maxBottom * 0.2;

    final topLines = lines.where((line) {
      if (line.bottom > threshold) return false;
      if (_isNoise(line.text)) return false;
      if (_looksLikeAmountOrDate(line.text)) return false;
      return true;
    }).toList();

    if (topLines.isEmpty) return null;

    topLines.sort((a, b) => b.height.compareTo(a.height));
    for (final line in topLines) {
      final name = _clean(line.text);
      if (name != null) return name;
    }
    return null;
  }

  String? _extractByScan(List<AiOcrLine> lines) {
    final sorted = [...lines]..sort((a, b) => a.top.compareTo(b.top));
    var checked = 0;
    for (final line in sorted) {
      if (checked >= kReceiptMerchantTopCandidateCount) break;
      if (_isNoise(line.text) || _looksLikeAmountOrDate(line.text)) continue;
      final name = _clean(line.text);
      if (name != null) return name;
      checked++;
    }
    return null;
  }

  String? _valueAfterLabel(String line, String label) {
    final index = line.indexOf(label);
    if (index < 0) return null;
    var value = line.substring(index + label.length).trim();
    value = value.replaceFirst(RegExp(r'^[：:\s]+'), '');
    return value.isEmpty ? null : value;
  }

  String? _clean(String raw) {
    var name = raw.trim().replaceAll(RegExp(r'\s+'), '');
    name = name.replaceFirst(kReceiptMerchantBranchSuffixPattern, '');
    if (name.length < kReceiptMerchantMinLength ||
        name.length > kReceiptMerchantMaxLength) {
      return null;
    }
    return name;
  }

  bool _isNoise(String text) {
    final trimmed = text.trim();
    if (kStatusBarTimePattern.hasMatch(trimmed)) return true;
    if (RegExp(r'^【.+】$').hasMatch(trimmed)) return true;
    if (trimmed == '结账单' || trimmed == '商品名称') return true;
    if (kMerchantNoiseTexts.any(text.contains)) return true;
    return kReceiptMerchantNoisePrefixes.any(trimmed.startsWith);
  }

  bool _looksLikeAmountOrDate(String text) {
    if (RegExp(r'[¥$]\s*[\d,.]+').hasMatch(text)) return true;
    if (RegExp(r'^\d+([.,]\d{1,2})?$').hasMatch(text.trim())) return true;
    if (RegExp(r'\d{4}[-/.年]\d{1,2}').hasMatch(text)) return true;
    return false;
  }
}
